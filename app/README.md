# Next.js Hello World App with Database Connectivity

This is a simple Next.js application that displays a "Hello World" message and checks database connectivity. It's designed to be run in a Docker container and connect to a PostgreSQL database.

## Prerequisites

- Docker
- PostgreSQL database (for local testing)

## Environment Variables

The application uses the following environment variables for database connection:

- `DB_USER`: Database user
- `DB_HOST`: Database host
- `DB_NAME`: Database name
- `DB_PASSWORD`: Database password
- `DB_PORT`: Database port (default is 5432)

For local development, you can create a `.env.local` file with these variables.

## Building the Docker Image

To build the Docker image, run the following command in the directory containing the Dockerfile:

```bash
docker build -t nextjs-hello-world .
```

This will create a Docker image named `nextjs-hello-world`.

## Running the Docker Container

To run the container, use the following command:

```bash
docker run -p 3000:3000 \
  -e DB_USER=your_db_user \
  -e DB_HOST=your_db_host \
  -e DB_NAME=your_db_name \
  -e DB_PASSWORD=your_db_password \
  -e DB_PORT=5432 \
  nextjs-hello-world
```

Replace the environment variable values with your actual database credentials.

Note: If you're running this locally and your database is on the host machine, you might need to use `host.docker.internal` as the `DB_HOST` value.

## Accessing the Application

Once the container is running, you can access the application by navigating to `http://localhost:3000` in your web browser.

## Development

For local development without Docker:

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create a `.env.local` file with your database credentials.

3. Run the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000](http://localhost:3000) in your browser to see the result.

## Notes for DevSecOps Assessment

- This application is a starting point for the DevSecOps assessment.
- In a production environment, you would need to consider secure ways of providing database credentials to the application, such as using AWS Secrets Manager.
- The Dockerfile provided is basic and might need optimization for a production environment.