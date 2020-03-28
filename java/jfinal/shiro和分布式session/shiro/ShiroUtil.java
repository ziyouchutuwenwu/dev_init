package server.shiro;

import com.jfinal.kit.LogKit;
import org.apache.shiro.SecurityUtils;
import org.apache.shiro.session.Session;
import org.apache.shiro.subject.Subject;
import java.util.Collection;

public class ShiroUtil {
    public static Subject getSubject(){
        return SecurityUtils.getSubject();
    }

    public static Object getUser(){
        return getSubject().getPrincipal();
    }

    public static Session getSession(){
        return SecurityUtils.getSubject().getSession();
    }

    public static boolean hasRole(String roleIdentifier){
        return getSubject().hasRole(roleIdentifier);
    }

    public static boolean hasAllRole(Collection<String> roleIdentifiers){
        return getSubject().hasAllRoles(roleIdentifiers);
    }

    public static boolean hasAnyRole(Collection<String> roleIdentifiers){
        boolean hasAnyRole = false;
        for (String role : roleIdentifiers) {
            if(hasRole(role)){
                hasAnyRole = true;
                break;
            }
        }
        return hasAnyRole;
    }

    public static boolean hasPermit(String permitIdentifier){
        return getSubject().isPermitted(permitIdentifier);
    }

    public static boolean hasAllPermit(String... permits){
        return getSubject().isPermittedAll(permits);
    }

    public static boolean hasAnyPermit(String... permits){
        boolean hasAnyPermit = false;
        for (String permit : permits) {
            if(hasPermit(permit)){
                hasAnyPermit = true;
                break;
            }
        }
        return hasAnyPermit;
    }
    public static void refreshSessionLastAccessTime(){
        try {
            getSession().touch();
        } catch (Throwable t) {
            LogKit.error("session.touch() method invocation has failed.", t);
        }
    }
    public static org.apache.shiro.mgt.SecurityManager getSecurityManager(){
        return  SecurityUtils.getSecurityManager();
    }
}