// Composables
import { createRouter, createWebHistory } from 'vue-router'
import { nextTick } from 'vue'
import { APP_NAMES } from '@/plugins/dictionary';
import { canisterImpl } from '@/services/icp-provider';
import { AuthClientApi } from '@/repository/auth-client-api';

// route imports
import DefaultLayout from '@/layouts/default-layout.vue'
import Dashboard from '@/pages/dashboard.vue'
import Marketplace from '@/pages/marketplace.vue'
import TokenDetails from '@/pages/token-details.vue'
import Settings from '@/pages/settings.vue'
import Support from '@/pages/support.vue'
import MyPortfolio from '@/pages/my-portfolio.vue'
import MyTransactions from '@/pages/my-transactions.vue'
import Profile from '@/pages/profile.vue'
import MarketTrends from '@/pages/market-trends.vue'
import Auth from '@/layouts/empty-layout.vue'
import Register from '@/pages/register.vue'
import Login from '@/pages/login.vue'
import PasswordReset from '@/pages/password-reset.vue'
import CeroSystem from '@/pages/cero-system.vue'

const DEFAULT_TITLE = APP_NAMES.capitalize;

const routes = [
  // ? Default routes
  {
    path: '/',
    component: DefaultLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: Dashboard,
        meta: { head: `Dashboard - ${DEFAULT_TITLE}` }
      },
      {
        path: 'marketplace',
        name: 'Marketplace',
        component: Marketplace,
        meta: { head: `Marketplace - ${DEFAULT_TITLE}` }
      },
      {
        path: '/token-details',
        name: 'TokenDetails',
        component: TokenDetails,
        meta: { head: `Token details - ${DEFAULT_TITLE}` }
      },
      {
        path: 'settings',
        name: 'Settings',
        component: Settings,
        meta: { head: `Settings - ${DEFAULT_TITLE}` }
      },
      {
        path: 'support',
        name: 'Support',
        component: Support,
        meta: { head: `Support - ${DEFAULT_TITLE}` }
      },
      {
        path: 'my-portfolio',
        name: 'MyPortfolio',
        component: MyPortfolio,
        meta: { head: `My portfolio - ${DEFAULT_TITLE}` }
      },
      {
        path: 'my-transactions',
        name: 'MyTransactions',
        component: MyTransactions,
        meta: { head: `My transactions - ${DEFAULT_TITLE}` }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: Profile,
        meta: { head: `Profile - ${DEFAULT_TITLE}` }
      },
    ],
  },


  // ? Authenticated routes
  {
    path: '/auth',
    component: Auth,
    children: [
      {
        path: 'register',
        name: 'Register',
        component: Register,
        meta: { head: `Register - ${DEFAULT_TITLE}` }
      },
      {
        path: 'login',
        name: 'Login',
        component: Login,
        meta: { head: `Login - ${DEFAULT_TITLE}` }
      },
      {
        path: 'password-reset',
        name: 'Password Reset',
        component: PasswordReset,
        meta: { head: `Password Reset - ${DEFAULT_TITLE}` }
      },
    ],
  },


  // ? Authenticated routes
  {
    path: '/cero-system',
    component: CeroSystem,
    meta: { system: true }
  }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
})


router.beforeEach(async (to, from, next) => {
  switch (to.path) {
    case '/':
      return next({ name: 'Dashboard', query: { ...canisterImpl, ...to.query } })

    case '/auth':
    case '/login':
      return next({ name: 'Login', query: { ...canisterImpl, ...to.query } })

    case '/register':
      return next({ name: 'Register', query: { ...canisterImpl, ...to.query } })
  }
  
  if (!Object.keys(to.query).includes('canisterId'))
  next({ name: to.name, query: { ...canisterImpl, ...to.query } });

  //!FIXME commented for testing
  // this route requires auth, check if logged in
  // if not, redirect to login page.
  const isAuthenticated = await AuthClientApi.isAuthenticated()
  if (to.matched.some(record => record.meta.requiresAuth) && !isAuthenticated)
    return next({ name: 'Login', query: { ...canisterImpl, ...to.query } })

  // go to wherever I'm going
  next()
})


router.afterEach((to, from) => {
  // Use next tick to handle router history correctly
  // see: https://github.com/vuejs/vue-router/issues/914#issuecomment-384477609
  nextTick(() => {
    if (to.meta.head) document.title = to.meta.head.toString();
    else document.title = DEFAULT_TITLE;
  });
});

export default router
