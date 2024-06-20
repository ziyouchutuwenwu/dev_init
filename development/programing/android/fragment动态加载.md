# fragment 动态加载

## 新建某 Fragment

## MainActivity 对应的布局里面

```xml
    <FrameLayout
        android:id="@+id/sub_menu_framelayout"
        android:layout_marginRight="20dp"
        android:layout_width="200dp"
        android:layout_height="match_parent"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintTop_toTopOf="parent">
    </FrameLayout>
```

### java 代码

```java
void switchToFragment1(){
    Fragment fragment = new SubMenu1Fragment();

    FragmentManager fragmentManager = getFragmentManager();
    FragmentTransaction transaction = fragmentManager.beginTransaction();
    transaction.replace(R.id.sub_menu_framelayout, fragment);
    transaction.commit();
}
```
