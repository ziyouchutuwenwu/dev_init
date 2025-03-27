from robyn import Robyn
import routes


app = Robyn(__file__)
routes.make(app)

if __name__ == "__main__":
    app.start(port=8080)