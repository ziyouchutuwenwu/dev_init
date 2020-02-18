package helper.shiro;

import com.jfinal.aop.Interceptor;
import com.jfinal.aop.Invocation;
import com.jfinal.core.Controller;
import com.jfinal.core.JFinal;
import org.apache.shiro.subject.Subject;
import org.apache.shiro.util.ThreadContext;
import org.apache.shiro.web.servlet.ShiroHttpServletRequest;
import org.apache.shiro.web.servlet.ShiroHttpServletResponse;
import org.apache.shiro.web.subject.WebSubject;

public class ShiroAuthInterceptor implements Interceptor {

    public void updateSubjectAndSession(Controller ctller){
        //对request和response进行包装
        ShiroHttpServletRequest request = new ShiroHttpServletRequest(ctller.getRequest(), JFinal.me().getServletContext(), true);
        ShiroHttpServletResponse response = new ShiroHttpServletResponse(ctller.getResponse(),JFinal.me().getServletContext(),request);

        //手动创建 Subject 对象
        Subject subject =(new WebSubject.Builder(request,response)).buildWebSubject();
        //绑定 subject 并 刷新session最后访问时间,延长session过期时间
        ThreadContext.bind(subject);
        ShiroUtil.refreshSessionLastAccessTime();
    }

    public void intercept(Invocation inv) {
        updateSubjectAndSession(inv.getController());

        inv.invoke();

        //核心逻辑
//        if(ShiroUtil.getSubject().isAuthenticated()){
//            LogKit.info("已经登陆");
//            if(ShiroUtil.hasRole("我是角色标识")){
//                //拥有该角色放行或者其他逻辑
//                inv.invoke();
//            }
//            // 例如 通过 inv.getActionKey() 是否一致判断拥有该权限；subject拥有的角色和权限都已经在自定义的realm的 doGetAuthorizationInfo中定义好了。
//            if(ShiroUtil.hasPermit("我是权限标识")){
//                //拥有该权限放行或者其他逻辑
//            }
//        }else{
//            LogKit.info("未登录");
//            //跳转登录或者其他逻辑处理
//            UsernamePasswordToken token = new UsernamePasswordToken("admin", "123");
//            ShiroUtil.getSubject().login(token);
//        }
    }
}