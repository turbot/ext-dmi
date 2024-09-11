resource "null_resource" "delete_default_vpc" {
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      # Get the default VPC ID
      VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region us-east-1 --query "Vpcs[0].VpcId" --output text)
      
      if [ "$VPC_ID" != "None" ]; then
        echo "Found default VPC: $VPC_ID"

        # Delete VPC Peering Connections (Requester and Accepter)
        PEERING_CONNECTIONS=$(aws ec2 describe-vpc-peering-connections --filters "Name=accepter-vpc-info.vpc-id,Values=$VPC_ID" --query "VpcPeeringConnections[].VpcPeeringConnectionId" --region us-east-1 --output text)
        for peering in $PEERING_CONNECTIONS; do
          echo "Deleting VPC Peering Connection as Accepter: $peering"
          aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $peering --region us-east-1
          aws ec2 wait vpc-peering-connection-deleted --vpc-peering-connection-ids $peering
        done

        PEERING_CONNECTIONS=$(aws ec2 describe-vpc-peering-connections --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" --query "VpcPeeringConnections[].VpcPeeringConnectionId" --region us-east-1 --output text)
        for peering in $PEERING_CONNECTIONS; do
          echo "Deleting VPC Peering Connection as Requester: $peering"
          aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $peering --region us-east-1
          aws ec2 wait vpc-peering-connection-deleted --vpc-peering-connection-ids $peering
        done

        # Delete Elastic IPs
        EIPS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query "Addresses[].AllocationId" --region us-east-1 --output text)
        for eip in $EIPS; do
          echo "Releasing Elastic IP: $eip"
          aws ec2 release-address --allocation-id $eip --region us-east-1
        done

        # Terminate Instances in the VPC
        INSTANCES=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" --query "Reservations[].Instances[].InstanceId" --region us-east-1 --output text)
        for instance in $INSTANCES; do
          echo "Terminating instance: $instance"
          aws ec2 terminate-instances --instance-ids $instance --region us-east-1
          aws ec2 wait instance-terminated --instance-ids $instance --region us-east-1
        done

        # Delete NAT Gateways
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[].NatGatewayId" --region us-east-1 --output text)
        for nat_gw in $NAT_GATEWAYS; do
          echo "Deleting NAT Gateway: $nat_gw"
          aws ec2 delete-nat-gateway --nat-gateway-id $nat_gw --region us-east-1
          aws ec2 wait nat-gateway-deleted --nat-gateway-ids $nat_gw --region us-east-1
        done

        # Delete VPC Endpoints (PrivateLink)
        ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[].VpcEndpointId" --region us-east-1 --output text)
        for endpoint in $ENDPOINTS; do
          echo "Deleting VPC Endpoint: $endpoint"
          aws ec2 delete-vpc-endpoint --vpc-endpoint-id $endpoint --region us-east-1
        done

        # Delete Network Interfaces (detach first if needed)
        NETWORK_INTERFACES=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[].NetworkInterfaceId" --region us-east-1 --output text)
        for eni in $NETWORK_INTERFACES; do
          echo "Deleting network interface: $eni"
          ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-ids $eni --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text --region us-east-1)
          if [ "$ATTACHMENT_ID" != "None" ]; then
            aws ec2 detach-network-interface --attachment-id $ATTACHMENT_ID --region us-east-1
          fi
          aws ec2 delete-network-interface --network-interface-id $eni --region us-east-1
        done

        # Delete Transit Gateway Attachments
        TRANSIT_ATTACHMENTS=$(aws ec2 describe-transit-gateway-vpc-attachments --filters "Name=vpc-id,Values=$VPC_ID" --query "TransitGatewayVpcAttachments[].TransitGatewayAttachmentId" --region us-east-1 --output text)
        for tgw_attachment in $TRANSIT_ATTACHMENTS; do
          echo "Deleting Transit Gateway Attachment: $tgw_attachment"
          aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id $tgw_attachment --region us-east-1
        done

        # Delete RDS Instances
        RDS_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC_ID'].DBInstanceIdentifier" --region us-east-1 --output text)
        for rds_instance in $RDS_INSTANCES; do
          echo "Deleting RDS instance: $rds_instance"
          aws rds delete-db-instance --db-instance-identifier $rds_instance --skip-final-snapshot --region us-east-1
          aws rds wait db-instance-deleted --db-instance-identifier $rds_instance --region us-east-1
        done

        # Delete Redshift Clusters
        REDSHIFT_CLUSTERS=$(aws redshift describe-clusters --query "Clusters[?VpcId=='$VPC_ID'].ClusterIdentifier" --region us-east-1 --output text)
        for redshift_cluster in $REDSHIFT_CLUSTERS; do
          echo "Deleting Redshift Cluster: $redshift_cluster"
          aws redshift delete-cluster --cluster-identifier $redshift_cluster --skip-final-cluster-snapshot --region us-east-1
          aws redshift wait cluster-deleted --cluster-identifier $redshift_cluster --region us-east-1
        done

        # Delete EFS (Elastic File Systems)
        EFS=$(aws efs describe-file-systems --query "FileSystems[?VpcId=='$VPC_ID'].FileSystemId" --region us-east-1 --output text)
        for efs_id in $EFS; do
          echo "Deleting EFS: $efs_id"
          aws efs delete-file-system --file-system-id $efs_id --region us-east-1
        done

        # Delete Elastic Beanstalk Environments
        EB_ENVIRONMENTS=$(aws elasticbeanstalk describe-environments --query "Environments[?VpcId=='$VPC_ID'].EnvironmentId" --region us-east-1 --output text)
        for eb_env in $EB_ENVIRONMENTS; do
          echo "Terminating Elastic Beanstalk Environment: $eb_env"
          aws elasticbeanstalk terminate-environment --environment-id $eb_env --region us-east-1
        done

        # Delete subnets
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-1 --query "Subnets[].SubnetId" --output text)
        for subnet in $SUBNETS; do
          echo "Deleting subnet: $subnet"
          aws ec2 delete-subnet --subnet-id $subnet --region us-east-1
        done

        # Delete Internet Gateway
        IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region us-east-1 --query "InternetGateways[0].InternetGatewayId" --output text)
        if [ "$IGW" != "None" ]; then
          echo "Detaching and deleting Internet Gateway: $IGW"
          aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region us-east-1
          aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region us-east-1
        fi

        # Delete Route Tables (except the main route table)
        ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-1 --query "RouteTables[?Associations[0].Main==false].RouteTableId" --output text)
        for rt in $ROUTE_TABLES; do
          echo "Deleting route table: $rt"
          aws ec2 delete-route-table --route-table-id $rt --region us-east-1
        done

        # Delete security groups (except the default security group)
        SGROUPS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-1 --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
        for sg in $SGROUPS; do
          echo "Deleting security group: $sg"
          aws ec2 delete-security-group --group-id $sg --region us-east-1
        done

        # Finally, delete the VPC
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id $VPC_ID --region us-east-1
      else
        echo "No default VPC found in region us-east-1"
      fi
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}
