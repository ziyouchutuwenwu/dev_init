# async

## 例子

```python
import asyncio


async def task(name: str, delay: float):
    """异步任务"""
    print(f"任务 {name} 开始...")
    await asyncio.sleep(delay)
    print(f"任务 {name} 完成!")
    return f"{name} 的结果"


async def main():
    tasks = [
        asyncio.create_task(task("A", 1)),
        asyncio.create_task(task("B", 2)),
        asyncio.create_task(task("C", 1.5)),
    ]

    print("=== 等待所有任务完成 ===")
    results = await asyncio.gather(*tasks)
    print("=== 全部完成 ===")

    for result in results:
        print(result)


if __name__ == "__main__":
    asyncio.run(main())

```
