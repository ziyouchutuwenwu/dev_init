package server.shiro;

import com.jfinal.aop.Inject;
import org.apache.shiro.authc.*;
import org.apache.shiro.authc.credential.CredentialsMatcher;
import org.apache.shiro.authz.AuthorizationInfo;
import org.apache.shiro.authz.SimpleAuthorizationInfo;
import org.apache.shiro.realm.AuthorizingRealm;
import org.apache.shiro.subject.PrincipalCollection;
import server.model.mapping.User;
import server.service.UserService;
import java.util.HashSet;
import java.util.Set;

public class ShiroAuthRealm extends AuthorizingRealm {

    // 无法注入，只能手工new
    UserService _service;

    public ShiroAuthRealm() {
        _service = new UserService();
    }

    public ShiroAuthRealm(CredentialsMatcher credentialsMatcher) {
        super(credentialsMatcher);
    }

    /**
     * 在这个方法中，进行登录验证
     * 验证当前登录的Subject
     * 当在登录时执行Subject.login()，就会调用下面的这个接口：
     */
    @Override
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) throws AuthenticationException {
        String userName = token.getPrincipal().toString();
        String password = new String((char[]) token.getCredentials());

        User user = _service.findByName(userName);
        if ( user == null || !user.get("password").equals(password) ) throw new UnknownAccountException();

        SimpleAuthenticationInfo authticInfo = new SimpleAuthenticationInfo(userName, password, getName());
        return authticInfo;
    }

    /**
     * 获取身份信息，我们可以在这个方法中，从数据库获取该用户的权限和角色信息
     */
    @Override
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        //能进入到这里，表示账号已经通过验证了
        String userName =(String) principals.getPrimaryPrincipal();

        //我们可以通过用户名从数据库获取权限/角色信息
        SimpleAuthorizationInfo authorizinfo = new SimpleAuthorizationInfo();

//        //权限
//        Set<String> permissions = new HashSet<String>();
//        permissions.add("printer:print");
//        permissions.add("printer:query");
//        authorizinfo.setStringPermissions(permissions);
//
//        //角色
//        Set<String> roles = new HashSet<String>();
//        roles.add("role1");
//        authorizinfo.setRoles(roles);

        return authorizinfo;
    }
}