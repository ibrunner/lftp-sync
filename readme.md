## Usage

- Pull image from docker hub: `ibrunner/lftp-sync:latest`
- Click "advanced settings"
- Environments tab:
  - Get address,user and password from [Feral Hosting](https://www.feralhosting.com/slots/pallas/ibrunner/software)
- Storage tab:
  - "Bind mount host path" to `/media/downloads` -> `/downloads`

## Configuration

### Environment Variables

| Variable          | Description                                     | Default                     |
| ----------------- | ----------------------------------------------- | --------------------------- |
| `FTP_HOST`        | FTP server address                              | (required)                  |
| `FTP_USER`        | FTP username                                    | (required)                  |
| `FTP_PASS`        | FTP password                                    | (required)                  |
| `REMOTE_DIR`      | Remote directory to sync from                   | `private/transmission/data` |
| `LOCAL_DIR`       | Local directory to sync to                      | `/downloads`                |
| `PARALLEL_JOBS`   | Number of parallel transfer jobs                | `3`                         |
| `CHUNKS_PER_FILE` | Number of chunks per file for parallel download | `15`                        |

### Volume Mounts

| Container Path | Purpose                                  |
| -------------- | ---------------------------------------- |
| `/downloads`   | Directory where files will be downloaded |
| `/config`      | Configuration and lock files storage     |

## Logging and Monitoring

- Transfer logs are stored in `/config/transfer.log`
- Container logs can be viewed in Container Station or using:
  ```bash
  docker logs lftp-sync
  ```

## Troubleshooting

### Common Issues

1. **Permission Issues**

   - Ensure the mounted volumes have correct permissions
   - QNAP typically uses user ID 1000
   - You may need to adjust permissions on the host:
     ```bash
     chmod -R 755 /share/your/download/path
     ```

2. **Connection Issues**

   - Verify FTP credentials
   - Check if FTP server is accessible from QNAP
   - Review logs for connection errors

3. **Container Won't Start**
   - Verify all required environment variables are set
   - Check container logs for startup errors
   - Ensure ports are not conflicting

## Maintenance

- The container automatically removes successfully downloaded files from the source
- Empty directories are cleaned up automatically
- Lock files in `/config` prevent duplicate downloads
- Container automatically restarts unless stopped manually

## Updates

To update the container:

1. In Container Station:

   - Pull the latest image
   - Remove the existing container
   - Create a new container with the same settings

2. Via command line:

   ```bash
   docker pull your-username/lftp-sync:latest
   docker stop lftp-sync
   docker rm lftp-sync
   # Run the docker run command again
   ```

3. Building multi-platform images:

   ```bash
   # Login to Docker Hub
   docker login

   docker buildx build --platform linux/amd64,linux/arm64 -t your-username/lftp-sync:latest --push .
   ```

   This builds and pushes the image for both AMD64 and ARM64 architectures.

## Support

For issues and feature requests, please create an issue on the GitHub repository.

## License

[Your License Here]
