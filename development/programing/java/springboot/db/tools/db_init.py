from prompter import yesno
import psycopg2


def open_db(ip, port, user, password, db):
    conn = psycopg2.connect(database=db, user=user, password=password, host=ip, port=port)
    return conn


def drop_db(conn, db):
    cur = conn.cursor()
    conn.autocommit = True
    sql = "drop database %s" % db
    cur.execute(sql)


def create_db(conn, db):
    cur = conn.cursor()
    conn.autocommit = True
    sql = "create database %s" % db
    cur.execute(sql)


def make_seeds(conn):
    cur = conn.cursor()

    cur.execute("create table if not exists users( id serial primary key, name character varying, age integer)")

    cur.execute("INSERT INTO users (name, age) VALUES ('aaa', 111)")
    cur.execute("INSERT INTO users (name, age) VALUES ('bbb', 222)")
    cur.execute("INSERT INTO users (name, age) VALUES ('ccc', 333)")
    cur.execute("INSERT INTO users (name, age) VALUES ('eee', 444)")
    cur.execute("INSERT INTO users (name, age) VALUES ('fff', 555)")
    cur.execute("INSERT INTO users (name, age) VALUES ('ggg', 666)")
    cur.execute("INSERT INTO users (name, age) VALUES ('hhh', 777)")
    cur.execute("INSERT INTO users (name, age) VALUES ('iii', 888)")
    cur.execute("INSERT INTO users (name, age) VALUES ('jjj', 999)")
    cur.execute("INSERT INTO users (name, age) VALUES ('kkk', 123)")

    conn.commit()
    conn.close()


if __name__ == "__main__":
    conn = open_db("127.0.0.1", "6543", "postgres", "postgres", "postgres")
    if True == yesno("is there old db existed?"):
        drop_db(conn, "my_db")
    create_db(conn, "my_db")

    conn = open_db("127.0.0.1", "6543", "postgres", "postgres", "my_db")
    make_seeds(conn)
