# DataMammoth API v2 Examples

Multi-language examples and tutorials for the DataMammoth API v2.

## Examples

| Directory | Language | Examples |
|---|---|---|
| `python/` | Python | List servers, create server, webhook listener |
| `typescript/` | TypeScript | List servers, create server, webhook listener |
| `go/` | Go | List servers, create server |
| `php/` | PHP | List servers, create server |
| `terraform/` | HCL | Basic server, full-stack infrastructure |
| `ansible/` | YAML | Provision server, configure firewall |
| `curl/` | Bash | Authentication, list servers, create server |

## Prerequisites

Set your API key:

```bash
export DM_API_KEY="dm_live_..."
```

## Quick Start

```bash
# curl -- list servers
bash curl/list_servers.sh

# Python -- list servers
pip install datamammoth
python python/list_servers.py

# TypeScript -- list servers
npm install @datamammoth/sdk
npx ts-node typescript/list_servers.ts

# Terraform -- provision a server
cd terraform/basic
terraform init && terraform apply
```

## License

MIT
