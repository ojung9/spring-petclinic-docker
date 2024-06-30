import boto3
import re

def get_latest_version():
    ecr = boto3.client('ecr', region_name='ap-northeast-2')
    response = ecr.describe_images(repositoryName='spring-petclinic-docker')
    tags = [tag for image in response['imageDetails'] for tag in image['imageTags']]
    version_tags = [tag for tag in tags if re.match(r'^\d+\.\d+\.\d+$', tag)]
    if version_tags:
        latest_version = max(version_tags, key=lambda x: list(map(int, x.split('.'))))
    else:
        latest_version = '0.0.0'
    print(latest_version)

if __name__ == "__main__":
    get_latest_version()