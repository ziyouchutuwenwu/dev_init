# json 处理

解析丢失`\`转义符的字符串会失败，推荐用来生成 json

## 例子

```go
package main

import (
    "fmt"
    "github.com/gogf/gf/v2/encoding/gjson"
)

func main() {
    data := `
    {"code":0,"output":{"details":[{"sentence":"虽然社会主义好。","index":0,"fragments":[{"action":"检查","collocation":[{"end_idx":2,"frag_ori":"虽然","start_idx":0}],"error_type":"SEMANTIC_ERROR","error_type_desc":"语义错误","explain":"关联词搭配缺失, 关联词:'虽然', 需要搭配['倒', '还是', '但是', '但', '可是', '却', '可', '仍', '仍然', '也']"}]},{"sentence":"一带一陆，是一家人工只能公司","index":8,"fragments":[{"action":"检查","collocation":[{"end_idx":16,"frag_ori":"家","start_idx":15},{"end_idx":18,"frag_ori":"人工","start_idx":16}],"error_type":"SEMANTIC_ERROR","error_type_desc":"语义错误","explain":"量名搭配错误，名词：'人工', 需要搭配['家']"}]},{"sentence":"一带一陆","index":8,"fragments":[{"action":"替换","end_idx":12,"error_type":"WORD_ERROR","error_type_desc":"字词错误","frag_fixed":"一带一路","frag_ori":"一带一陆","start_idx":8}]},{"sentence":"是一家人工只能公司","index":13,"fragments":[{"action":"替换","end_idx":22,"error_type":"WORD_ERROR","error_type_desc":"字词错误","frag_fixed":"智能公司","frag_ori":"只能公司","start_idx":18}]}],"has_error":true}}
    `
    jsonObject, _ := gjson.DecodeToJson(data)
    array := jsonObject.Get("output.details").Array()

    for i := 0; i < len(array); i++ {
        sentenceItem := array[i].(map[string]interface{})
        sentenceIndex := int(sentenceItem["index"].(float64))
        fragments := (sentenceItem["fragments"]).([]interface{})
        for j := 0; j < len(fragments); j++ {
            fragment := fragments[j].(map[string]interface{})
            fragment["type"] = 11111

            if _, ok := fragment["start_idx"]; ok {
                fragment["offset"] = 3 * (int(fragment["start_idx"].(float64)) - sentenceIndex)
            }

            if _, ok := fragment["collocation"]; ok {
                collocations := fragment["collocation"].([]interface{})
                for k := 0; k < len(collocations); k++ {
                    collocationItem := collocations[k].(map[string]interface{})
                    if _, ok := collocationItem["start_idx"]; ok {
                        collocationItem["offset"] = 3 * (int(collocationItem["start_idx"].(float64)) - sentenceIndex)
                    }
                }
            }
        }
    }

    totalResultJson, _ := jsonObject.ToJsonString()
    fmt.Println(totalResultJson)
}
```

## 注意

gf 里面的 array 转 json 的时候，需要转换为 go 原生的 array

```golang
func demo() g.Array {
    result := garray.New()
    result.Append(1)

    return result.Slice()
}

func main() {
    list := demo()
    result := gjson.New(list)
    fmt.Println(result.MustToJsonString())
}
```
