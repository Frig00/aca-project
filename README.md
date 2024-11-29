# Optimizing Path Tracing Workflows with MPI and Cloud Computing

![Path Tracing Sample Image](https://github.com/ferraridavide/aca-project/blob/master/src/output_0000.png)

## Abstract

This project focuses on parallelizing a path tracing workflow using the c-ray library and MPI. We implemented two parallelization methods: tiling and sampling. The development process involved local testing with Docker containers for rapid iterative development and deployment on Google Cloud Platform Compute Engine using Terraform for automation. The study explores the performance of various configurations in distributed rendering, providing insights into the scalability of path tracing across multiple nodes.

## Table of Contents

- [Workload](#workload)
- [Development Process](#development-process)
- [Results](#results)
- [Cost Analysis](#cost-analysis)
- [Conclusions](#conclusions)

## Workload

Our project parallelizes a path tracing workflow, an advanced rendering technique used in computer graphics to create highly realistic images. We used the open-source C library c-ray for our implementation.


## Development Process

### Library Used

We used the c-ray library, fixed at commit 84109d4.

### Development Environment

- Makefile for compilation
- GNU Debugger (GDB) for troubleshooting
- Docker-based local cluster for testing

### Parallelization Strategies

1. Tiling Mode
2. Sampling Mode

### Cloud Migration

We transitioned to Google Cloud Platform (GCP) using Compute Engine, testing various cluster configurations:

- Fat Cluster
- Light Cluster
- Intra-Regional vs. Inter-Regional Clusters

### Automated Deployment

We used Terraform for automated deployment on GCP.

## Results

| Node type    | Tiling (s) | Sampling (s) | Speedup tiling | Speedup sampling |
|--------------|------------|--------------|----------------|------------------|
| e2-highcpu-4 | 17.921311  | 14.835419    | 3.90x          | 4.73x            |
| e2-highcpu-8 | 17.867890  | 14.862826    | 3.93x          | 4.72x            |
| c4-highcpu-4 | 14.147418  | 8.455381     | 2.33x          | 3.90x            |
| c2-standard-4| 22.916034  | 12.791110    | 2.19x          | 3.93x            |

## Cost Analysis

We analyzed the cost-effectiveness of different VM configurations on GCP for rendering tasks.

## Conclusions

1. Fat clusters demonstrated better speedup ratios compared to light clusters.
2. Inter-regional clusters experienced performance degradation due to increased network latency.
3. Light clusters offer a cost-effective alternative for less intensive tasks.
4. Fat clusters are preferred for high-quality final renders.

For more detailed information, please refer to the full report.

## Contributors

- Andrea Frigatti
- Davide Ferrari
