curl -X POST http://localhost:8080/v1/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sample-job",
    "schedule": "@every 1m",
    "executor": "shell",
    "executor_config": {
      "command": "bash -c \"python ~/autopython/PortableGit/bin/test.py\""
    }
  }'