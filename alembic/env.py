from logging.config import fileConfig
from sqlalchemy import pool, create_engine
from alembic import context

from app.db_base import Base
from app import models  # Make sure all models are imported!
target_metadata = Base.metadata

# --- Alembic Config object ---
config = context.config

# --- DB URL override logic ---
db_url = config.get_main_option("sqlalchemy.url")
x_args = context.get_x_argument(as_dictionary=True)
if "db_url" in x_args:
    db_url = x_args["db_url"]
# ----------------------------

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = db_url
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = create_engine(db_url, poolclass=pool.NullPool)
    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()