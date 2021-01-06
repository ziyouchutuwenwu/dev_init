# 自定义 ui 控件

## 比如需要在某 activity 里面加载某个自定义 ui 控件

- 先在 activity 的 xml 里面测试好大概的布局和设置参数等等
- 然后新建一个 layout 的 xml，剪切相关内容到里面，根据情况，这个 xml 可以选用 RelativeLayout 或者 LinerLayout
- 创建一个 class，在构造函数里面，调用如下代码，view 可以用来 findViewById

```java
LayoutInflater inflater = LayoutInflater.from(context);
View view = inflater.inflate(R.layout.gender_switch_button_layout, this);
```

原来的 activity 的 xml 里面，直接使用类似下面的代码

```xml
<aa.bb.customview.genderbutton.GenderButtonView
    android:id="@+id/female_button"
    android:layout_width="0dp"
    android:layout_height="0dp"
    android:layout_marginRight="23dp"
    android:background="@drawable/right_corner_round_gray_view"
    app:layout_constraintBottom_toBottomOf="@+id/name_edit_text"
    app:layout_constraintEnd_toEndOf="@+id/mask_frame_view"
    app:layout_constraintStart_toEndOf="@id/male_button"
    app:layout_constraintTop_toTopOf="@+id/name_edit_text"
    />
```
