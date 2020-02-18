package helper.shiro;

import com.jfinal.plugin.IPlugin;
import org.apache.shiro.SecurityUtils;
import org.apache.shiro.mgt.DefaultSecurityManager;
import org.apache.shiro.realm.Realm;
import org.apache.shiro.realm.text.IniRealm;
import org.apache.shiro.web.mgt.DefaultWebSecurityManager;
import org.apache.shiro.web.servlet.Cookie;
import org.apache.shiro.web.servlet.SimpleCookie;
import org.apache.shiro.web.session.mgt.DefaultWebSessionManager;
import java.util.Collection;
import helper.session.RedisSessionManager;
import helper.session.RedisSessionDAO;

public class ShiroPlugin implements IPlugin {

    /**
     * shiro的核心控制器，大脑
     */
    private DefaultSecurityManager securityManager = new DefaultWebSecurityManager();
    /**
     * 设置session管理器 为 DefaultWebSessionManager（否则默认为ServletContainerSessionManager）
     * private DefaultWebSessionManager sessionManager = new DefaultWebSessionManager();
     */
    private DefaultWebSessionManager sessionManager = new RedisSessionManager();
    private RedisSessionDAO sessionDAO = new RedisSessionDAO();
    /**
     * 单位毫秒 全局的 session过期时间，默认就是30分钟（1800000）
     */
    private long globalSessionTimeout = 1800000L;
    /**
     *  与tomcat等web容器的默认的cookie中的键值 JSESSIONID冲突（ShiroHttpSession，中常量默认值JSESSIONID）
     *  会导致session的覆盖或丢失等问题
     */
    private final String SESSION_ID_NAME = "WEB_SESSIONID";

    public ShiroPlugin(){
    }

    public ShiroPlugin(Realm realm) {
        securityManager.setRealm(realm);
    }

    public ShiroPlugin(Collection <Realm> realms) {
        securityManager.setRealms(realms);
    }

    //如果通过ini文件来设置realm 那么需要配置
    public ShiroPlugin(String iniPath) {
        IniRealm iniRealm = new IniRealm(iniPath);
        securityManager.setRealm(iniRealm);
    }

    private void init(){
        Cookie cookie = new SimpleCookie(SESSION_ID_NAME);

        sessionManager.setSessionDAO(sessionDAO);
        sessionManager.setSessionIdCookie(cookie);
        sessionManager.setGlobalSessionTimeout(globalSessionTimeout);
        //sessionManager.setCacheManager(cacheManager);缓存管理器 TODO

        securityManager.setSessionManager(sessionManager);
        //securityManager.setCacheManager(cacheManager);缓存管理器 TODO
        SecurityUtils.setSecurityManager(securityManager);
    }

    @Override
    public boolean start() {
        init();
        return true;
    }
    @Override
    public boolean stop() {
        return true;
    }

    public DefaultSecurityManager getSecurityManager() {
        return securityManager;
    }
    public void setSecurityManager(DefaultSecurityManager securityManager) {
        this.securityManager = securityManager;
    }
    public DefaultWebSessionManager getSessionManager() {
        return sessionManager;
    }
    public void setSessionManager(DefaultWebSessionManager sessionManager) {
        this.sessionManager = sessionManager;
    }
    public long getGlobalSessionTimeout() {
        return globalSessionTimeout;
    }
    public void setGlobalSessionTimeout(long globalSessionTimeout) {
        this.globalSessionTimeout = globalSessionTimeout;
    }
}