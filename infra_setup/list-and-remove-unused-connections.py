import boto3

# Initialize boto3 clients
s = boto3.Session(profile_name="mmur-admin")

codestar_connections_client = s.client('codestar-connections')
codepipeline_client = s.client('codepipeline')

# List all CodeStar Connections
all_connections_response = codestar_connections_client.list_connections()
all_connections = [connection['ConnectionArn'] for connection in all_connections_response['Connections']]

# List all CodePipelines
pipelines_response = codepipeline_client.list_pipelines()
pipelines = [pipeline['name'] for pipeline in pipelines_response['pipelines']]

# Initialize a dictionary to hold used connections and their pipelines
used_connections = {}

# Iterate over each pipeline to get the Source stage connections
for pipeline in pipelines:
    pipeline_details = codepipeline_client.get_pipeline(name=pipeline)
    stages = pipeline_details['pipeline']['stages']
    for stage in stages:
        if stage['name'] == 'Source':
            for action in stage['actions']:
                if action['actionTypeId']['provider'] == 'CodeStarSourceConnection':
                    connection_arn = action['configuration'].get('ConnectionArn')
                    if connection_arn:
                        if connection_arn not in used_connections:
                            used_connections[connection_arn] = [pipeline]
                        else:
                            used_connections[connection_arn].append(pipeline)

# Find connections that are not used in any Source stage
unused_connections = [conn for conn in all_connections if conn not in used_connections]

# Print the used connections and their pipelines
if not used_connections:
    print("No used CodeStar Connections found.")
else:
    print("Used CodeStar Connections and their Pipelines:")
    for connection, pipelines in used_connections.items():
        print(f"Connection ARN: {connection}")
        print(f"Pipelines: {', '.join(pipelines)}")
        print("----------------------------------------")

# Print and delete the unused connections
if not unused_connections:
    print("No unused CodeStar Connections found.")
else:
    print("Unused CodeStar Connections:")
    for connection in unused_connections:
        print(connection)
        # Delete the unused connection
        codestar_connections_client.delete_connection(ConnectionArn=connection)
        print(f"Deleted connection: {connection}")