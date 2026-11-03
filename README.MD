# DevOps Basics

- Learning AWS services(Application Load Balancer, Auto Scaling Group)
- Managing AWS service by Terraform
- Use Docker Image to speed up building server
- Implement CI/CD with GitHub Actions

## Architecture

1. To visualize how Auto Scaling works, I made a web service that shows the IP address of server
2. I made a script that gives fake traffic (loadtest.py) to increase the number of servers. 
3. When request is processed from different server, the web shows different ip address. 

## Automation

- Terraform: make and destroy AWS Service(ALB, Security Group, ASG) by "Terraform apply", "Terraform destroy".
- Docker: reduce time to implement new server. When ASG increases the server, the user data script pulls the image from Docker Hub and runs it as a container. 
- GitHub Actions: When I do "git push", it checks out my connected repository and builds docker image, and pushes it to Docker Hub. Mine does not test the code yet. 



