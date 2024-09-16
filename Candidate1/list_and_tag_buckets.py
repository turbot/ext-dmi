import boto3
import argparse

# Initialize boto3 S3 client
s3_client = boto3.client('s3')

def get_bucket_versioning_status(bucket_name):
    """
    Get the versioning status of an S3 bucket.
    Returns 'Enabled', 'Suspended', or 'None'.
    """
    versioning = s3_client.get_bucket_versioning(Bucket=bucket_name)
    return versioning.get('Status', 'None')

def tag_bucket(bucket_name, dry_run):
    """
    Tag the S3 bucket with the tag 'Candidate1': 'true'.
    If in dry-run mode, print what would happen instead of tagging.
    """
    if dry_run:
        print(f"[DRY-RUN] Would tag bucket {bucket_name} with 'Candidate1':'true'.")
    else:
        try:
            s3_client.put_bucket_tagging(
                Bucket=bucket_name,
                Tagging={
                    'TagSet': [
                        {
                            'Key': 'Candidate1',
                            'Value': 'true'
                        }
                    ]
                }
            )
            print(f"Bucket {bucket_name} tagged with 'Candidate1':'true'.")
        except Exception as e:
            print(f"Error tagging bucket {bucket_name}: {e}")

def list_and_tag_buckets(dry_run):
    """
    List all buckets, print their versioning status, and tag those with versioning enabled.
    If in dry-run mode, simulate the tagging.
    """
    try:
        # List all buckets
        buckets = s3_client.list_buckets()

        for bucket in buckets['Buckets']:
            bucket_name = bucket['Name']
            versioning_status = get_bucket_versioning_status(bucket_name)

            print(f"Bucket: {bucket_name}, Versioning Status: {versioning_status}")

            # If versioning is enabled, tag the bucket (or simulate if dry-run)
            if versioning_status == 'Enabled':
                tag_bucket(bucket_name, dry_run)

    except Exception as e:
        print(f"Error listing buckets: {e}")

if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description='List and tag S3 buckets based on versioning status.')
    parser.add_argument('--dry-run', action='store_true', help='Perform a dry-run (no changes will be made).')
    
    args = parser.parse_args()

    # Run the function with the appropriate dry-run setting
    print(f"Dry-run mode is {'enabled' if args.dry_run else 'disabled'}.")
    list_and_tag_buckets(args.dry_run)

