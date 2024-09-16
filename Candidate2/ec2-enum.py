import boto3
from botocore.exceptions import ClientError

def list_buckets(s3_client):
    """List all S3 buckets in the account."""
    response = s3_client.list_buckets()
    return response.get('Buckets', [])

def get_versioning_status(s3_client, bucket_name):
    """Get the versioning status of a given S3 bucket."""
    try:
        response = s3_client.get_bucket_versioning(Bucket=bucket_name)
        return response.get('Status', 'Not Enabled')
    except ClientError as e:
        print(f"Error getting versioning status for bucket {bucket_name}: {e}")
        return 'Error'

def tag_bucket(s3_client, bucket_name):
    """Tag the bucket with 'Candidate2': 'true'."""
    try:
        s3_client.put_bucket_tagging(
            Bucket=bucket_name,
            Tagging={
                'TagSet': [
                    {
                        'Key': 'Candidate2',
                        'Value': 'true'
                    }
                ]
            }
        )
        print(f"Tagged bucket {bucket_name} with 'Candidate2': 'true'")
    except ClientError as e:
        print(f"Error tagging bucket {bucket_name}: {e}")

def main():
    s3_client = boto3.client('s3')

    buckets = list_buckets(s3_client)

    for bucket in buckets:
        bucket_name = bucket['Name']
        versioning_status = get_versioning_status(s3_client, bucket_name)
        print(f"Bucket Name: {bucket_name}, Versioning Status: {versioning_status}")

        if versioning_status == 'Enabled':
            tag_bucket(s3_client, bucket_name)

if __name__ == "__main__":
    main()
