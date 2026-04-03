"""
SnapDev – The Developer Command & Learning Hub
Flask Backend — All routes, all data, zero databases.
"""

from flask import Flask, render_template

app = Flask(__name__)

# ─────────────────────────────────────────────────────────────────────────────
# DATA — All content lives here as Python dicts. Clean, readable, portable.
# ─────────────────────────────────────────────────────────────────────────────

LINUX_COMMANDS = [
    {"name": "ls", "desc": "List files and directories in the current location.", "example": "ls -la"},
    {"name": "cd", "desc": "Change the current working directory.", "example": "cd /var/www/html"},
    {"name": "pwd", "desc": "Print the full path of the current directory.", "example": "pwd"},
    {"name": "mkdir", "desc": "Create a new directory.", "example": "mkdir -p projects/snapdev"},
    {"name": "rm", "desc": "Remove files or directories. Use -rf for recursive deletion.", "example": "rm -rf old_folder/"},
    {"name": "cp", "desc": "Copy files or directories to a destination.", "example": "cp -r src/ backup/"},
    {"name": "mv", "desc": "Move or rename files and directories.", "example": "mv app.py server.py"},
    {"name": "cat", "desc": "Display the contents of a file in the terminal.", "example": "cat requirements.txt"},
    {"name": "grep", "desc": "Search for patterns inside files using regex.", "example": "grep -r 'def ' *.py"},
    {"name": "find", "desc": "Search for files and directories by name or type.", "example": "find . -name '*.log'"},
    {"name": "chmod", "desc": "Change file or directory permissions.", "example": "chmod +x deploy.sh"},
    {"name": "chown", "desc": "Change the owner of a file or directory.", "example": "chown ubuntu:ubuntu app.py"},
    {"name": "ps", "desc": "Display currently running processes.", "example": "ps aux | grep python"},
    {"name": "kill", "desc": "Terminate a process using its PID.", "example": "kill -9 1234"},
    {"name": "top", "desc": "Real-time view of system resource usage.", "example": "top"},
    {"name": "df", "desc": "Show disk space usage of mounted filesystems.", "example": "df -h"},
    {"name": "du", "desc": "Estimate file and directory disk usage.", "example": "du -sh *"},
    {"name": "curl", "desc": "Transfer data from or to a URL via the command line.", "example": "curl -X GET https://api.example.com/data"},
    {"name": "ssh", "desc": "Securely connect to a remote machine.", "example": "ssh ubuntu@192.168.1.100"},
    {"name": "tar", "desc": "Archive files into a tarball or extract one.", "example": "tar -czvf archive.tar.gz folder/"},
]

GIT_COMMANDS = [
    {"name": "git init", "desc": "Initialize a new Git repository in the current directory.", "example": "git init"},
    {"name": "git clone", "desc": "Clone an existing remote repository locally.", "example": "git clone https://github.com/user/repo.git"},
    {"name": "git status", "desc": "Show the state of the working directory and staging area.", "example": "git status"},
    {"name": "git add", "desc": "Stage files for the next commit.", "example": "git add . or git add app.py"},
    {"name": "git commit", "desc": "Record staged changes with a descriptive message.", "example": "git commit -m 'feat: add login route'"},
    {"name": "git push", "desc": "Upload local commits to a remote repository.", "example": "git push origin main"},
    {"name": "git pull", "desc": "Fetch and merge changes from the remote branch.", "example": "git pull origin main"},
    {"name": "git branch", "desc": "List, create, or delete branches.", "example": "git branch feature/new-ui"},
    {"name": "git checkout", "desc": "Switch to a different branch or restore files.", "example": "git checkout -b hotfix/login-bug"},
    {"name": "git merge", "desc": "Merge another branch into the current branch.", "example": "git merge feature/new-ui"},
    {"name": "git log", "desc": "View the commit history of the current branch.", "example": "git log --oneline --graph"},
    {"name": "git diff", "desc": "Show differences between working tree and last commit.", "example": "git diff HEAD"},
    {"name": "git stash", "desc": "Temporarily save uncommitted changes to a stack.", "example": "git stash push -m 'wip: refactor routes'"},
    {"name": "git reset", "desc": "Undo commits or unstage files.", "example": "git reset --soft HEAD~1"},
    {"name": "git rebase", "desc": "Reapply commits on top of another base branch.", "example": "git rebase main"},
    {"name": "git remote", "desc": "Manage remote repository connections.", "example": "git remote add origin https://github.com/user/repo.git"},
    {"name": "git tag", "desc": "Create a named reference to a specific commit.", "example": "git tag -a v1.0.0 -m 'Initial release'"},
    {"name": "git fetch", "desc": "Download remote changes without merging them.", "example": "git fetch origin"},
    {"name": "git cherry-pick", "desc": "Apply a specific commit from another branch.", "example": "git cherry-pick abc1234"},
    {"name": "git blame", "desc": "Show who last modified each line of a file.", "example": "git blame app.py"},
]

DOCKER_COMMANDS = [
    {"name": "docker build", "desc": "Build an image from a Dockerfile in the current directory.", "example": "docker build -t snapdev:latest ."},
    {"name": "docker run", "desc": "Create and start a new container from an image.", "example": "docker run -d -p 5000:5000 snapdev"},
    {"name": "docker ps", "desc": "List all running containers.", "example": "docker ps -a"},
    {"name": "docker stop", "desc": "Gracefully stop one or more running containers.", "example": "docker stop container_id"},
    {"name": "docker rm", "desc": "Remove one or more stopped containers.", "example": "docker rm container_id"},
    {"name": "docker rmi", "desc": "Delete one or more images from the local registry.", "example": "docker rmi snapdev:latest"},
    {"name": "docker pull", "desc": "Download an image from Docker Hub or a registry.", "example": "docker pull python:3.11-slim"},
    {"name": "docker push", "desc": "Upload a local image to Docker Hub or a registry.", "example": "docker push username/snapdev:latest"},
    {"name": "docker exec", "desc": "Run a command inside a running container.", "example": "docker exec -it myapp bash"},
    {"name": "docker logs", "desc": "Fetch and stream logs from a container.", "example": "docker logs -f container_id"},
    {"name": "docker images", "desc": "List all locally stored Docker images.", "example": "docker images"},
    {"name": "docker volume", "desc": "Manage persistent data volumes.", "example": "docker volume create mydata"},
    {"name": "docker network", "desc": "Manage Docker networks for container communication.", "example": "docker network create mynet"},
    {"name": "docker inspect", "desc": "View detailed metadata about a container or image.", "example": "docker inspect container_id"},
    {"name": "docker-compose up", "desc": "Start all services defined in a docker-compose.yml file.", "example": "docker-compose up -d --build"},
    {"name": "docker-compose down", "desc": "Stop and remove all containers defined in compose file.", "example": "docker-compose down -v"},
    {"name": "docker system prune", "desc": "Remove unused containers, images, and volumes.", "example": "docker system prune -af"},
    {"name": "docker cp", "desc": "Copy files between a container and the host machine.", "example": "docker cp myapp:/app/log.txt ./log.txt"},
    {"name": "docker tag", "desc": "Tag an image with a new name or version.", "example": "docker tag snapdev:latest snapdev:v1.0"},
    {"name": "docker stats", "desc": "Stream real-time resource usage for containers.", "example": "docker stats --no-stream"},
]

PYTHON_TIPS = [
    {"name": "List Comprehension", "desc": "Build lists concisely in a single readable expression.", "example": "squares = [x**2 for x in range(10) if x % 2 == 0]"},
    {"name": "f-Strings", "desc": "Format strings cleanly with embedded expressions (Python 3.6+).", "example": 'name = \"Atlas\"\nprint(f\"Hello, {name}!\")'},
    {"name": "Unpacking", "desc": "Assign multiple variables from a sequence in one line.", "example": "a, b, *rest = [1, 2, 3, 4, 5]"},
    {"name": "enumerate()", "desc": "Iterate with both index and value without a counter variable.", "example": "for i, item in enumerate(['a','b','c']):\n    print(i, item)"},
    {"name": "zip()", "desc": "Iterate over multiple iterables in parallel.", "example": "for name, score in zip(names, scores):\n    print(name, score)"},
    {"name": "defaultdict", "desc": "A dict that auto-initializes missing keys with a default value.", "example": "from collections import defaultdict\nd = defaultdict(list)\nd['key'].append(1)"},
    {"name": "Context Managers", "desc": "Use 'with' to automatically handle resource cleanup.", "example": "with open('file.txt', 'r') as f:\n    data = f.read()"},
    {"name": "Walrus Operator", "desc": "Assign and use a variable in the same expression (Python 3.8+).", "example": "if n := len(data):\n    print(f'{n} items found')"},
    {"name": "Dataclasses", "desc": "Auto-generate boilerplate for data-holding classes.", "example": "from dataclasses import dataclass\n@dataclass\nclass User:\n    name: str\n    age: int"},
    {"name": "Type Hints", "desc": "Annotate function signatures for clarity and IDE support.", "example": "def greet(name: str) -> str:\n    return f'Hello {name}'"},
    {"name": "Lambda Functions", "desc": "Create anonymous one-liner functions inline.", "example": "double = lambda x: x * 2\nsorted_list = sorted(data, key=lambda x: x['age'])"},
    {"name": "try / except / finally", "desc": "Handle exceptions gracefully and always run cleanup code.", "example": "try:\n    result = 10 / x\nexcept ZeroDivisionError:\n    result = 0\nfinally:\n    print('done')"},
    {"name": "Generator Expressions", "desc": "Memory-efficient alternative to list comprehensions.", "example": "total = sum(x**2 for x in range(1000000))"},
    {"name": "functools.lru_cache", "desc": "Cache expensive function results automatically.", "example": "from functools import lru_cache\n@lru_cache(maxsize=128)\ndef fib(n): return n if n < 2 else fib(n-1)+fib(n-2)"},
    {"name": "Dictionary Merge (3.9+)", "desc": "Merge two dicts cleanly using the | operator.", "example": "merged = dict_a | dict_b"},
    {"name": "pathlib", "desc": "Work with file paths in an object-oriented, cross-platform way.", "example": "from pathlib import Path\npath = Path('data') / 'output.csv'\npath.mkdir(parents=True, exist_ok=True)"},
    {"name": "any() / all()", "desc": "Check conditions across iterables in one expression.", "example": "if all(score > 50 for score in scores):\n    print('Everyone passed')"},
    {"name": "__slots__", "desc": "Reduce memory usage in classes with fixed attributes.", "example": "class Point:\n    __slots__ = ['x', 'y']\n    def __init__(self, x, y):\n        self.x, self.y = x, y"},
    {"name": "Unpacking in Calls", "desc": "Pass lists or dicts as arguments using * and **.", "example": "args = [1, 2]\nkwargs = {'sep': '-'}\nprint(*args, **kwargs)"},
    {"name": "collections.Counter", "desc": "Count hashable elements efficiently.", "example": "from collections import Counter\ncounts = Counter(['a','b','a','c','b','a'])\nprint(counts.most_common(2))"},
]

FLASK_TIPS = [
    {"name": "App Factory Pattern", "desc": "Create your Flask app inside a function for better modularity and testing.", "example": "def create_app():\n    app = Flask(__name__)\n    app.config.from_object('config.Config')\n    return app"},
    {"name": "Blueprints", "desc": "Organize routes into modular, reusable components.", "example": "from flask import Blueprint\nauth = Blueprint('auth', __name__)\n@auth.route('/login')\ndef login(): ..."},
    {"name": "Environment Config", "desc": "Load config from environment variables for 12-factor compliance.", "example": "import os\napp.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev')"},
    {"name": "url_for()", "desc": "Generate URLs dynamically from endpoint names — never hardcode.", "example": "from flask import url_for\nurl_for('auth.login')  # → /login"},
    {"name": "flash() Messages", "desc": "Send one-time messages between requests using the session.", "example": "from flask import flash\nflash('Login successful!', 'success')"},
    {"name": "request Object", "desc": "Access all incoming request data — form, JSON, args, headers.", "example": "from flask import request\ndata = request.get_json()\nname = request.form.get('name')"},
    {"name": "jsonify()", "desc": "Return JSON responses with correct content-type headers.", "example": "from flask import jsonify\nreturn jsonify({'status': 'ok', 'data': result})"},
    {"name": "Before/After Request", "desc": "Run functions before or after every request automatically.", "example": "@app.before_request\ndef log_request():\n    print(f'Request: {request.method} {request.path}')"},
    {"name": "Error Handlers", "desc": "Return custom pages for 404, 500, and other HTTP errors.", "example": "@app.errorhandler(404)\ndef not_found(e):\n    return render_template('404.html'), 404"},
    {"name": "Jinja2 Filters", "desc": "Transform template output using built-in or custom filters.", "example": "{{ user.created_at | datetimeformat }}\n{{ name | upper | truncate(20) }}"},
    {"name": "Template Inheritance", "desc": "Reduce repetition using a base layout that child templates extend.", "example": "{% extends 'base.html' %}\n{% block content %}\n  <h1>Hello</h1>\n{% endblock %}"},
    {"name": "g Object", "desc": "Store request-scoped data accessible throughout the request lifecycle.", "example": "from flask import g\ng.user = get_current_user()"},
    {"name": "session", "desc": "Store signed client-side session data between requests.", "example": "from flask import session\nsession['user_id'] = user.id"},
    {"name": "abort()", "desc": "Immediately raise an HTTP error response from any point in code.", "example": "from flask import abort\nif not user: abort(403)"},
    {"name": "send_file()", "desc": "Serve files (images, PDFs, CSVs) directly from Flask routes.", "example": "from flask import send_file\nreturn send_file('report.csv', as_attachment=True)"},
    {"name": "Static Files", "desc": "Flask serves static assets from the /static folder automatically.", "example": "<!-- In HTML -->\n<link rel='stylesheet' href=\"{{ url_for('static', filename='style.css') }}\">"},
    {"name": "Testing with pytest", "desc": "Use Flask's test client to write reliable integration tests.", "example": "def test_home(client):\n    resp = client.get('/')\n    assert resp.status_code == 200"},
    {"name": "Logging", "desc": "Use Flask's built-in logger for structured application logging.", "example": "app.logger.info('User logged in: %s', user.id)\napp.logger.error('DB connection failed')"},
    {"name": "app.config", "desc": "Centralize all configuration using Flask's config dictionary.", "example": "app.config.update(\n    DEBUG=True,\n    TESTING=False\n)"},
    {"name": "CLI Commands", "desc": "Register custom Flask CLI commands using @app.cli.command.", "example": "@app.cli.command('seed-db')\ndef seed_db():\n    print('Seeding database...')"},
]

# ─────────────────────────────────────────────────────────────────────────────
# ROUTES
# ─────────────────────────────────────────────────────────────────────────────

@app.route("/")
def index():
    """Homepage — shows the main hub with navigation cards."""
    return render_template("index.html")


@app.route("/linux")
def linux():
    """Linux Commands reference page."""
    return render_template("linux.html", commands=LINUX_COMMANDS)


@app.route("/git")
def git():
    """Git Commands reference page."""
    return render_template("git.html", commands=GIT_COMMANDS)


@app.route("/docker")
def docker():
    """Docker Commands reference page."""
    return render_template("docker.html", commands=DOCKER_COMMANDS)


@app.route("/python")
def python():
    """Python Tips reference page."""
    return render_template("python.html", commands=PYTHON_TIPS)


@app.route("/flask")
def flask_tips():
    """Flask Tips reference page."""
    return render_template("flask.html", commands=FLASK_TIPS)


# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
