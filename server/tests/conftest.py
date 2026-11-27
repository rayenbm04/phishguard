import pytest

from phishguard_server.main import app, get_stores
from phishguard_server.storage import Stores


@pytest.fixture(autouse=True)
def stores(tmp_path):
    """Each test writes its verdicts and feedback in its own temporary folder."""
    s = Stores(tmp_path)
    app.dependency_overrides[get_stores] = lambda: s
    yield s
    app.dependency_overrides.pop(get_stores, None)
