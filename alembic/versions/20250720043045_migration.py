"""migration

Revision ID: 20250720043045
Revises: 20250719234917
Create Date: 2025-07-20 04:30:46.132641

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '20250720043045'
down_revision: Union[str, Sequence[str], None] = '20250719234917'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
