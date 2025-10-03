# -*- coding: utf-8 -*-
"""
A script to connect to an OpenStack cloud and list all server instances
in a specific project, ordered by their launch date from oldest to newest.

Prerequisites:
- Python 3
- Required packages installed (`pip install openstacksdk python-dateutil`)
- An OpenStack clouds.yaml file or environment variables (OS_*)
  configured for authentication. See the README.md for more details.
"""

import os
import sys
import argparse
import datetime
import openstack
from openstack.exceptions import SDKException
from dateutil import parser as date_parser
from dateutil.relativedelta import relativedelta
from dateutil.tz import tzutc


def list_instances_by_launch_date(cloud, project_name):
    """
    Connects to an OpenStack cloud, queries instances in a specific project,
    and lists them sorted by launch date.

    :param str cloud: The name of the cloud configuration to use from your
                      clouds.yaml file. Can be None.
    :param str project_name: The name of the project to search for instances.
    """
    try:
        # Step 1: Initialize and connect to the cloud.
        if cloud:
            print(f"▶️  Connecting to cloud configuration: '{cloud}'...")
            conn = openstack.connect(cloud=cloud)
        else:
            print("▶️  Connecting using OS_* environment variables...")
            conn = openstack.connect()

        print("✅ Connection successful.")

        # Step 2: Find the project by name to get its ID.
        print(f"🔎 Searching for project: '{project_name}'...")
        project = conn.identity.find_project(project_name, ignore_missing=False)
        if not project:
            print(f"❌ Error: Project '{project_name}' not found.", file=sys.stderr)
            return
            
        print(f"✅ Found project '{project.name}' with ID: {project.id}")

        # Step 3: List all servers (instances) in the specified project.
        print(f"📋 Fetching instances for project '{project.name}'...")
        servers = list(conn.compute.servers(project_id=project.id, all_projects=True))

        if not servers:
            print(f"ℹ️  No instances found in project '{project_name}'.")
            return
            
        print(f"✅ Found {len(servers)} instances. Applying filter...")

        # Step 4: Filter the servers to include only those older than one month.
        now_utc = datetime.datetime.now(tzutc())
        one_month_ago = now_utc - relativedelta(months=1)

        filtered_servers = [
            server for server in servers
            if date_parser.parse(server.created_at) < one_month_ago
        ]
        
        if not filtered_servers:
            print(f"ℹ️  No instances found in project '{project_name}' that are older than one month.")
            return

        # Step 5: Sort the filtered servers by the 'created_at' attribute.
        sorted_servers = sorted(filtered_servers, key=lambda server: server.created_at)
        print(f"✅ Found and sorted {len(sorted_servers)} instances older than one month.")

        # Step 6: Print the sorted list of servers in a formatted table.
        # Create a cache to store user names to avoid redundant API calls.
        user_cache = {}

        print("\n--- Instances in Project '{}' (Launched >1 Month Ago, Oldest to Newest) ---".format(project_name))
        print(
            f"{'Name':<30} {'ID':<38} {'Owner':<20} {'Status':<10} {'Launched (UTC)':<28}"
        )
        print("-" * 130)
        for server in sorted_servers:
            owner_name = user_cache.get(server.user_id)
            if not owner_name:
                try:
                    # Fetch user from the identity service
                    user = conn.identity.get_user(server.user_id)
                    owner_name = user.name
                    # Cache the result
                    user_cache[server.user_id] = owner_name
                except SDKException:
                    # If user is not found or another error occurs, use a placeholder
                    owner_name = "N/A"
                    user_cache[server.user_id] = owner_name
            
            print(
                f"{server.name:<30.30} {server.id:<38} {owner_name:<20.20} {server.status:<10} {server.created_at:<28}"
            )
        print("-" * 130)
        print("\n")

    except SDKException as e:
        print(f"❌ An OpenStack SDK error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="List instances in an OpenStack project, sorted by creation date."
    )
    
    # Add --project argument
    parser.add_argument(
        "-p", "--project",
        default=os.environ.get('OS_PROJECT_NAME'),
        required=os.environ.get('OS_PROJECT_NAME') is None,
        help="The project name to query. Defaults to OS_PROJECT_NAME env var."
    )

    # Add --cloud argument
    parser.add_argument(
        "-c", "--cloud",
        default=os.environ.get('OS_CLOUD'),
        help="The cloud name from your clouds.yaml. Defaults to OS_CLOUD env var. If omitted, uses standard OS_* variables."
    )
    
    args = parser.parse_args()

    list_instances_by_launch_date(cloud=args.cloud, project_name=args.project)


