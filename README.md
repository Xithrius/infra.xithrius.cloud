# infra.xithrius.cloud

Infrastructure configuration for xithrius.cloud services

## PostgreSQL setup

1. Copy `.env.sample` to `.env`

Then place credentials into any key starting with `POSTGRES_`. These will be credentials for the elevated user.

2. Create database and user (optional)

If the database and/or user already exist, then they will not be modified.

Using the credentials you put into the `.env` file,

> [!IMPORTANT]
> Put a space before the command in your prompt if you don't want it to be recorded in bash history

Order of arguments: elevated username, new database name, new user's name, new user's password:

```bash
 ./scripts/postgres-user-database.sh elevated_user databasename asdf very_important_password
```

3. Make sure all is well by connecting to the database

```bash
docker exec -it infraxithriuscloud-postgres-1 psql -U auser -d databasename
```
