package mysql_demo

import (
    "fmt"
    "github.com/casbin/casbin/v2"
    gormadapter "github.com/casbin/gorm-adapter/v3"
    _ "github.com/go-sql-driver/mysql"
)

func Demo() {
    hasPermission := false

    adapter, _ := gormadapter.NewAdapter(
      "mysql", "root:root@tcp(127.0.0.1:4407)/",
      "casbin", "casbin_rule")

    enforcer, _ := casbin.NewEnforcer("./model.conf", adapter)

    enforcer.LoadPolicy()

    hasPermission, _ = enforcer.Enforce("dajun", "data1", "read")
    fmt.Println(hasPermission)

    hasPermission, _ = enforcer.Enforce("lizi", "data2", "write")
    fmt.Println(hasPermission)

    enforcer.AddPolicy("mmc", "data1", "write")
    enforcer.SavePolicy()
    hasPermission, _ = enforcer.Enforce("mmc", "data1", "write")
    fmt.Println(hasPermission)

    hasPermission, _ = enforcer.Enforce("dajun", "data2", "read")
    fmt.Println(hasPermission)
}
