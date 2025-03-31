 # type: ignore
from robyn import Robyn
import routes
import argparse

app = Robyn(__file__)
routes.make(app)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', required=True, help='监听端口')
    args = parser.parse_args()

    app.start(host="0.0.0.0", port=args.port)