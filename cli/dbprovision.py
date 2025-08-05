#!/usr/bin/env python3

import argparse
import json
import os
import sys
import subprocess
import yaml
from pathlib import Path
from typing import Dict, List, Optional
from enum import Enum

class ClusterType(Enum):
    STANDALONE = "standalone"
    REPLICASET = "replicaset"
    SHARDED = "sharded"

class CloudProvider(Enum):
    GCP = "gcp"
    AWS = "aws"
    AZURE = "azure"

class MongoDBVersion(Enum):
    V7_0 = "7.0"
    V8_0 = "8.0"

class StorageEngine(Enum):
    WIRED_TIGER = "wiredTiger"

class AuthMechanism(Enum):
    SCRAM_SHA_256 = "SCRAM-SHA-256"

class DBProvision:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.terraform_dir = self.project_root / "infra/terraform"
        self.ansible_dir = self.project_root / "infra/ansible"
        self.scripts_dir = self.project_root / "infra/scripts"
        
    def validate_parameters(self, args):
        errors = []
        
        if args.cluster_type == ClusterType.SHARDED.value:
            if args.mongos_count < 1:
                errors.append("Sharded cluster requires at least 1 mongos instance")
            if args.shard_count < 1:
                errors.append("Sharded cluster requires at least 1 shard")
                
        if args.replica_nodes < 1:
            errors.append("Replica nodes must be at least 1")
        if args.replica_nodes % 2 == 0:
            print("Warning: Even number of replica nodes may cause split-brain issues")
            
        if args.mongodb_port and not (1024 <= args.mongodb_port <= 65535):
            errors.append("MongoDB port must be between 1024 and 65535")
            
        if not args.project_id:
            errors.append("GCP project ID is required")
            
        if errors:
            for error in errors:
                print(f"Error: {error}")
            sys.exit(1)
            
    def generate_terraform_vars(self, args) -> Dict:
        vars_config = {
            "project_id": args.project_id,
            "region": args.region,
            "cluster_type": args.cluster_type,
            "mongodb_version": args.mongodb_version,
            "replica_nodes": args.replica_nodes,
            "instance_type": args.instance_type,
            "disk_size": args.disk_size,
            "disk_type": args.disk_type,
            "enable_auth": args.enable_auth,
            "enable_tls": args.enable_tls,
            "monitoring_enabled": args.monitoring_enabled,
            "backup_enabled": args.backup_enabled,
        }
        
        if args.cluster_type == ClusterType.SHARDED.value:
            vars_config.update({
                "shard_count": args.shard_count,
                "config_servers": args.config_servers,
                "mongos_count": args.mongos_count,
            })
            
        if args.zones:
            vars_config["zones"] = args.zones.split(",")
            
        if args.vpc_name:
            vars_config["vpc_name"] = args.vpc_name
            
        if args.subnet_cidr:
            vars_config["subnet_cidr"] = args.subnet_cidr
            
        return vars_config
        
    def generate_ansible_vars(self, args) -> Dict:
        vars_config = {
            "mongodb_version": args.mongodb_version,
            "replica_set_name": args.replica_set_name,
            "storage_engine": args.storage_engine,
            "enable_auth": args.enable_auth,
            "enable_tls": args.enable_tls,
            "auth_mechanism": args.auth_mechanism,
        }
        
        if args.cache_size:
            vars_config["cache_size"] = args.cache_size
            
        if args.oplog_size:
            vars_config["oplog_size"] = args.oplog_size
            
        if args.backup_schedule:
            vars_config["backup_schedule"] = args.backup_schedule
            
        return vars_config
        
    def run_terraform(self, action: str, vars_file: str):
        os.chdir(self.terraform_dir)
        
        if action == "init":
            cmd = ["terraform", "init"]
        elif action == "plan":
            cmd = ["terraform", "plan", f"-var-file={vars_file}"]
        elif action == "apply":
            cmd = ["terraform", "apply", f"-var-file={vars_file}", "-auto-approve"]
        elif action == "destroy":
            cmd = ["terraform", "destroy", f"-var-file={vars_file}", "-auto-approve"]
        else:
            raise ValueError(f"Unknown terraform action: {action}")
            
        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Terraform {action} failed:")
            print(result.stderr)
            sys.exit(1)
            
        return result.stdout
        
    def run_ansible(self, playbook: str, inventory: str, vars_file: Optional[str] = None):
        os.chdir(self.ansible_dir)
        
        cmd = ["ansible-playbook", "-i", f"inventories/{inventory}", f"playbooks/{playbook}"]
        
        if vars_file:
            cmd.extend(["-e", f"@{vars_file}"])
            
        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Ansible playbook {playbook} failed:")
            print(result.stderr)
            sys.exit(1)
            
        return result.stdout
        
    def create_cluster(self, args):
        print(f"Creating MongoDB {args.cluster_type} cluster...")
        
        cluster_name = f"{args.cluster_name or 'mongodb-cluster'}"
        
        terraform_vars = self.generate_terraform_vars(args)
        ansible_vars = self.generate_ansible_vars(args)
        
        terraform_vars_file = self.terraform_dir / f"{cluster_name}.tfvars"
        ansible_vars_file = self.ansible_dir / f"group_vars/{cluster_name}.yml"
        
        with open(terraform_vars_file, 'w') as f:
            for key, value in terraform_vars.items():
                if isinstance(value, str):
                    f.write(f'{key} = "{value}"\n')
                elif isinstance(value, list):
                    f.write(f'{key} = {json.dumps(value)}\n')
                else:
                    f.write(f'{key} = {value}\n')
                    
        ansible_vars_file.parent.mkdir(exist_ok=True)
        with open(ansible_vars_file, 'w') as f:
            yaml.dump(ansible_vars, f)
            
        try:
            print("1. Initializing Terraform...")
            self.run_terraform("init", str(terraform_vars_file))
            
            print("2. Planning infrastructure...")
            self.run_terraform("plan", str(terraform_vars_file))
            
            print("3. Creating infrastructure...")
            terraform_output = self.run_terraform("apply", str(terraform_vars_file))
            
            print("4. Configuring MongoDB...")
            if args.cluster_type == ClusterType.STANDALONE.value:
                self.run_ansible("deploy-standalone.yml", f"{cluster_name}.ini", str(ansible_vars_file))
            elif args.cluster_type == ClusterType.REPLICASET.value:
                self.run_ansible("deploy-replicaset.yml", f"{cluster_name}.ini", str(ansible_vars_file))
                self.run_ansible("init-replica-set.yml", f"{cluster_name}.ini", str(ansible_vars_file))
            elif args.cluster_type == ClusterType.SHARDED.value:
                self.run_ansible("deploy-config-servers.yml", f"config-servers.ini", str(ansible_vars_file))
                self.run_ansible("init-config-replica-set.yml", f"config-servers.ini", str(ansible_vars_file))
                self.run_ansible("deploy-shard-servers.yml", f"shard-servers.ini", str(ansible_vars_file))
                self.run_ansible("init-shard-replica-sets.yml", f"shard-servers.ini", str(ansible_vars_file))
                self.run_ansible("deploy-mongos.yml", f"mongos.ini", str(ansible_vars_file))
                self.run_ansible("configure-sharding.yml", f"mongos.ini", str(ansible_vars_file))
                
            print("5. Cluster deployment completed successfully!")
            self.show_cluster_info(cluster_name, args.cluster_type)
            
        except Exception as e:
            print(f"Deployment failed: {e}")
            sys.exit(1)
            
    def show_cluster_info(self, cluster_name: str, cluster_type: str):
        print("\n" + "="*50)
        print(f"MongoDB Cluster: {cluster_name}")
        print("="*50)
        
        if cluster_type == ClusterType.SHARDED.value:
            print("Connection Endpoints (mongos):")
            print("- Use these endpoints to connect your applications")
            print("- Format: mongodb://host1:27016,host2:27016/")
        elif cluster_type == ClusterType.REPLICASET.value:
            print("Connection Endpoints (Replica Set):")
            print("- Use these endpoints to connect your applications")
            print("- Format: mongodb://host1:27017,host2:27017,host3:27017/?replicaSet=rs0")
        else:
            print("Connection Endpoint (Standalone):")
            print("- Format: mongodb://host:27017/")
        
        print("\nNext Steps:")
        print("1. Test connectivity: dbprovision health --cluster", cluster_name)
        print("2. Check status: dbprovision status --cluster", cluster_name)
        print("3. Scale cluster: dbprovision scale --cluster", cluster_name, "--shards 5")
        print("4. Backup data: dbprovision backup --cluster", cluster_name)
        
    def show_status(self, cluster_name: str):
        print(f"Checking status for cluster: {cluster_name}")
        
    def show_health(self, cluster_name: str, check_all: bool = False):
        print(f"Health check for cluster: {cluster_name}")
        
    def destroy_cluster(self, cluster_name: str):
        print(f"Destroying cluster: {cluster_name}")
        
        terraform_vars_file = self.terraform_dir / f"{cluster_name}.tfvars"
        
        if not terraform_vars_file.exists():
            print(f"Terraform vars file not found: {terraform_vars_file}")
            sys.exit(1)
            
        print("WARNING: This will permanently delete all resources!")
        confirm = input("Type 'yes' to confirm: ")
        
        if confirm.lower() == 'yes':
            self.run_terraform("destroy", str(terraform_vars_file))
            terraform_vars_file.unlink()
            print("Cluster destroyed successfully!")
        else:
            print("Destruction cancelled.")

def create_parser():
    parser = argparse.ArgumentParser(
        description="MongoDB Cluster Provisioning CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create a 3-node replica set
  dbprovision create --cluster-type replicaset --replica-nodes 3 --project-id my-project

  # Create a sharded cluster with 3 shards
  dbprovision create --cluster-type sharded --shards 3 --project-id my-project

  # Check cluster status
  dbprovision status --cluster my-cluster

  # Destroy cluster
  dbprovision destroy --cluster my-cluster
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    create_parser = subparsers.add_parser('create', help='Create a new MongoDB cluster')
    create_parser.add_argument('--cluster-name', type=str, help='Cluster name')
    create_parser.add_argument('--cluster-type', choices=[e.value for e in ClusterType], 
                              default=ClusterType.REPLICASET.value, help='Cluster type')
    create_parser.add_argument('--cloud-provider', choices=[e.value for e in CloudProvider], 
                              default=CloudProvider.GCP.value, help='Cloud provider')
    create_parser.add_argument('--project-id', type=str, required=True, help='GCP project ID')
    create_parser.add_argument('--region', type=str, default='asia-northeast3', help='GCP region')
    create_parser.add_argument('--zones', type=str, help='Comma-separated zones (e.g., a,b,c)')
    
    create_parser.add_argument('--mongodb-version', choices=[e.value for e in MongoDBVersion], 
                              default=MongoDBVersion.V8_0.value, help='MongoDB version')
    create_parser.add_argument('--replica-nodes', type=int, default=3, help='Number of replica nodes')
    create_parser.add_argument('--replica-set-name', type=str, default='rs0', help='Replica set name')
    create_parser.add_argument('--mongodb-port', type=int, help='MongoDB port')
    
    create_parser.add_argument('--shard-count', type=int, default=3, help='Number of shards (sharded only)')
    create_parser.add_argument('--config-servers', type=int, default=3, help='Number of config servers')
    create_parser.add_argument('--mongos-count', type=int, default=2, help='Number of mongos instances')
    
    create_parser.add_argument('--instance-type', type=str, default='e2-standard-4', help='VM instance type')
    create_parser.add_argument('--disk-size', type=int, default=100, help='Disk size in GB')
    create_parser.add_argument('--disk-type', type=str, default='pd-ssd', help='Disk type')
    
    create_parser.add_argument('--vpc-name', type=str, help='VPC network name')
    create_parser.add_argument('--subnet-cidr', type=str, help='Subnet CIDR')
    
    create_parser.add_argument('--storage-engine', choices=[e.value for e in StorageEngine], 
                              default=StorageEngine.WIRED_TIGER.value, help='Storage engine')
    create_parser.add_argument('--cache-size', type=str, help='WiredTiger cache size (e.g., 1GB)')
    create_parser.add_argument('--oplog-size', type=str, help='Oplog size (e.g., 1024MB)')
    
    create_parser.add_argument('--enable-auth', action='store_true', default=True, help='Enable authentication')
    create_parser.add_argument('--enable-tls', action='store_true', help='Enable TLS encryption')
    create_parser.add_argument('--auth-mechanism', choices=[e.value for e in AuthMechanism], 
                              default=AuthMechanism.SCRAM_SHA_256.value, help='Authentication mechanism')
    create_parser.add_argument('--keyfile-path', type=str, help='Cluster keyfile path')
    
    create_parser.add_argument('--monitoring-enabled', action='store_true', help='Enable monitoring (Prometheus/Grafana)')
    create_parser.add_argument('--backup-enabled', action='store_true', help='Enable automatic backup')
    create_parser.add_argument('--backup-schedule', type=str, default='0 2 * * *', help='Backup schedule (cron format)')
    
    status_parser = subparsers.add_parser('status', help='Show cluster status')
    status_parser.add_argument('--cluster', type=str, required=True, help='Cluster name')
    
    health_parser = subparsers.add_parser('health', help='Health check for cluster')
    health_parser.add_argument('--cluster', type=str, required=True, help='Cluster name')
    health_parser.add_argument('--check-all', action='store_true', help='Check all components')
    
    destroy_parser = subparsers.add_parser('destroy', help='Destroy a cluster')
    destroy_parser.add_argument('--cluster', type=str, required=True, help='Cluster name')
    
    return parser

def main():
    parser = create_parser()
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
        
    db_provision = DBProvision()
    
    if args.command == 'create':
        db_provision.validate_parameters(args)
        db_provision.create_cluster(args)
    elif args.command == 'status':
        db_provision.show_status(args.cluster)
    elif args.command == 'health':
        db_provision.show_health(args.cluster, args.check_all)
    elif args.command == 'destroy':
        db_provision.destroy_cluster(args.cluster)

if __name__ == "__main__":
    main()