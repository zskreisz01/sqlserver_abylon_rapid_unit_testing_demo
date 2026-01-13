# Use official Microsoft SQL Server 2025 image as base
FROM mcr.microsoft.com/mssql/server:2025-latest

# Switch to root user to install additional tools if needed
USER root

# Set environment variables
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

# Switch back to mssql user
USER mssql

# Expose SQL Server port
EXPOSE 1433

# SQL Server will start automatically via the base image's entrypoint
