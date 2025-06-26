import boto3
from diagrams import Diagram, Cluster
from diagrams.aws.compute import EC2, ECS, Lambda
from diagrams.aws.database import RDS

from diagrams.aws.network import ELB, VPC, Route53, CloudFront
from diagrams.aws.storage import S3
from diagrams.aws.security import IAM
from diagrams.aws.management import Cloudwatch
from diagrams.aws.integration import SQS, SNS
import os
from dotenv import load_dotenv

load_dotenv()

class AWSArchitectureDiagram:
    def __init__(self):
        # Initialize AWS clients
        self.ec2 = boto3.client('ec2')
        self.rds = boto3.client('rds')
        self.s3 = boto3.client('s3')
        self.lambda_client = boto3.client('lambda')
        self.elb = boto3.client('elbv2')
        self.ecs = boto3.client('ecs')
        
    def get_resources(self):
        """Fetch AWS resources"""
        resources = {
            'ec2': self.ec2.describe_instances()['Reservations'],
            'rds': self.rds.describe_db_instances()['DBInstances'],
            's3': self.s3.list_buckets()['Buckets'],
            'lambda': self.lambda_client.list_functions()['Functions'],
            'elb': self.elb.describe_load_balancers()['LoadBalancers'],
            'ecs': self.ecs.list_clusters()['clusterArns']
        }
        return resources
    
    def generate_diagram(self, filename="aws_architecture"):
        """Generate architecture diagram"""
        resources = self.get_resources()
        
        with Diagram(filename, show=False, direction="TB"):
            # Networking
            with Cluster("VPC"):
                dns = Route53("Route53")
                cf = CloudFront("CloudFront")
                
                # Load Balancers
                if resources['elb']:
                    lb = ELB("ALB")
                    dns >> cf >> lb
                
                # Compute
                with Cluster("Compute"):
                    if resources['ec2']:
                        ec2_instances = [EC2(f"EC2-{i+1}") for i in range(len(resources['ec2']))]
                        if 'lb' in locals():
                            lb >> ec2_instances
                    
                    if resources['lambda']:
                        lambda_fns = [Lambda(f"Lambda-{fn['FunctionName']}") for fn in resources['lambda']]
                    
                    if resources['ecs']:
                        ecs_clusters = [ECS(f"ECS-{cluster.split('/')[-1]}") for cluster in resources['ecs']]
                
                # Databases
                with Cluster("Databases"):
                    if resources['rds']:
                        rds_instances = [RDS(f"RDS-{db['DBInstanceIdentifier']}") for db in resources['rds']]
                    
                
                # Storage
                if resources['s3']:
                    s3_buckets = [S3(f"S3-{bucket['Name']}") for bucket in resources['s3']]
            
            # Monitoring
            cw = Cloudwatch("CloudWatch")
            if 'ec2_instances' in locals():
                cw << ec2_instances
            if 'lambda_fns' in locals():
                cw << lambda_fns
            
            # IAM
            iam = IAM("IAM")
            if 'ec2_instances' in locals():
                iam - ec2_instances
            
            # Messaging (example)
            with Cluster("Messaging"):
                sqs = SQS("SQS")
                sns = SNS("SNS")
                if 'lambda_fns' in locals():
                    lambda_fns >> sqs
                    sns >> lambda_fns

if __name__ == "__main__":
    print("Generating AWS Architecture Diagram...")
    diagram_generator = AWSArchitectureDiagram()
    diagram_generator.generate_diagram()
    print("Diagram generated as 'aws_architecture.png'")