package helper.shiro;

import org.apache.shiro.authc.AuthenticationException;
import org.apache.shiro.authc.AuthenticationInfo;
import org.apache.shiro.authc.AuthenticationToken;
import org.apache.shiro.authc.SimpleAuthenticationInfo;
import org.apache.shiro.authc.credential.CredentialsMatcher;
import org.apache.shiro.authz.AuthorizationInfo;
import org.apache.shiro.authz.SimpleAuthorizationInfo;
import org.apache.shiro.realm.AuthorizingRealm;
import org.apache.shiro.subject.PrincipalCollection;
import java.util.HashSet;
import java.util.Set;

public class ShiroAuthRealm extends AuthorizingRealm {

    public ShiroAuthRealm() {
    }

    public ShiroAuthRealm(CredentialsMatcher credentialsMatcher) {
        super(credentialsMatcher);
    }

    /**
     * 在这个方法中，进行登录验证
     */
    @Override
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) throws AuthenticationException {
        String userName = token.getPrincipal().toString();
        String password = new String((char[]) token.getCredentials());

        SimpleAuthenticationInfo authticInfo = new SimpleAuthenticationInfo(userName, password, getName());
        return authticInfo;
    }

    /**
     * 获取身份信息，我们可以在这个方法中，从数据库获取该用户的权限和角色信息
     */
    @Override
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        String username = (String) getAvailablePrincipal(principals);

        //我们可以通过用户名从数据库获取权限/角色信息
        SimpleAuthorizationInfo authorizinfo = new SimpleAuthorizationInfo();

        //权限
        Set<String> permissions = new HashSet<String>();
        permissions.add("printer:print");
        permissions.add("printer:query");
        authorizinfo.setStringPermissions(permissions);

        //角色
        Set<String> roles = new HashSet<String>();
        roles.add("role1");
        authorizinfo.setRoles(roles);

        return authorizinfo;
    }
}