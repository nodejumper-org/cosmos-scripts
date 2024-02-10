# Optimism Node Installation Guide

This guide details the steps to set up an Optimism node with Docker, including the configuration to connect with the Ethereum mainnet via Alchemy and essential management commands.

## Prerequisites

Ensure your system meets these requirements:
- 16GB+ RAM
- 2TB SSD (NVME Recommended)
- 100mb/s+ Download

## Step 1: Install Docker and Docker Compose

### Install Docker and Docker Compose

```bash
sudo apt update
sudo apt install -y curl gnupg ca-certificates lsb-release

### Download the docker gpg file to Ubuntu and docker compose support to the Ubuntu's packages list
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### Install docker and docker compose on Ubuntu
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker $(whoami)
```

Verify the installations:

```bash
docker --version
docker-compose --version
```

## Step 2: Sign Up for Alchemy

Create an account at [alchemy.com](https://alchemy.com/) to get your Ethereum mainnet RPC endpoint.

## Step 3: Clone the Repository

```bash
git clone https://github.com/smartcontracts/simple-optimism-node.git
cd simple-optimism-node
```

## Step 4: Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

Update the `.env` file with your Alchemy endpoint and the following settings:

```dotenv
NETWORK_NAME=op-mainnet
NODE_TYPE=full
HEALTHCHECK__REFERENCE_RPC_PROVIDER=https://mainnet.optimism.io
OP_GETH__HISTORICAL_RPC=https://mainnet.optimism.io

OP_NODE__RPC_ENDPOINT=<Your-Alchemy-ETH-Mainnet-RPC-Endpoint>
OP_NODE__RPC_TYPE=alchemy
```

## Step 5: Start the Node

```bash
docker-compose up -d
```

## Step 6: Monitor Your Node

To check the logs and monitor the node's activity:

```bash
docker-compose logs -f
```

## Node Management

- **View Logs**: To view the node's logs, use the command provided above.
- **Stop the Node**: To stop your Optimism node, run:

```bash
docker-compose down
```

- **Remove the Node**: If you wish to remove your node completely, including all data:

```bash
docker-compose down --volumes
```

This will stop and remove all containers, networks, and volumes associated with your Optimism node.

## Updating the Node

To update your node, fetch the latest changes and restart the node:

```bash
git pull
docker-compose down
docker-compose up -d
```
