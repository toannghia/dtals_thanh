import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../store/auth';

const routes = [
    {
        path: '/login',
        name: 'Đăng nhập',
        component: () => import('../views/Auth/Login.vue'),
        meta: { public: true }
    },
    {
        path: '/register',
        name: 'Đăng ký',
        component: () => import('../views/Auth/Register.vue'),
        meta: { public: true }
    },
    {
        path: '/auth/activate',
        name: 'Kích hoạt tài khoản',
        component: () => import('../views/Auth/Activate.vue'),
        meta: { public: true }
    },
    {
        path: '/auth/reset-password',
        name: 'Khôi phục mật khẩu',
        component: () => import('../views/Auth/ResetPassword.vue'),
        meta: { public: true }
    },
    {

        path: '/',
        component: () => import('../layouts/AdminLayout.vue'),
        meta: { requiresAuth: true },
        children: [
            { path: '', name: 'Bảng điều khiển', component: () => import('../views/Dashboard/Index.vue') },
            { path: 'users', name: 'Danh sách khách hàng', component: () => import('../views/Users/Index.vue') },
            { path: 'users/:id', name: 'Chi tiết khách hàng', component: () => import('../views/Users/Detail.vue') },
            { path: 'system-users', name: 'Nhân viên', component: () => import('../views/Users/SystemUsers.vue') },
            { path: 'stations', name: 'Trạm CORS', component: () => import('../views/Stations/Index.vue') },
            { path: 'stations/map', name: 'Bản đồ trạm', component: () => import('../views/Stations/Map.vue') },
            { path: 'ntrip-accounts', name: 'Tài khoản NTRIP', component: () => import('../views/NtripAccounts/Index.vue') },
            { path: 'ntrip-packages', name: 'Gói thuê bao', component: () => import('../views/NtripPackages/Index.vue') },
            { path: 'ntrip-checkout', name: 'Thanh toán', component: () => import('../views/NtripPackages/MultiCheckout.vue') },
            { path: 'finance', name: 'Tài chính', component: () => import('../views/Finance/Index.vue') },
            { path: 'revenue-report', name: 'Báo cáo doanh thu', component: () => import('../views/RevenueReport/Index.vue') },
            { path: 'ekyc', name: 'Quản lý eKYC', component: () => import('../views/Ekyc/KycManagement.vue') },
            { path: 'tickets', name: 'Yêu cầu từ CQNN', component: () => import('../views/Tickets/AdminTickets.vue') },
            { path: 'system/roles', name: 'Phân quyền', component: () => import('../views/System/RoleManagement.vue') },
            { path: 'system/auth-config', name: 'Cấu hình xác thực', component: () => import('../views/System/AuthConfig.vue') },
            { path: 'system/payos-config', name: 'Cấu hình thanh toán', component: () => import('../views/System/PayosConfig.vue') },
            { path: 'profile', name: 'Hồ sơ cá nhân', component: () => import('../views/Profile/Index.vue') },
            { path: 'support', name: 'Quản lý yêu cầu hỗ trợ', component: () => import('../views/Admin/Support/SupportManagement.vue') },
            { path: 'support/:id', name: 'Chi tiết yêu cầu (Admin)', component: () => import('../views/Admin/Support/AdminSupportDetail.vue') },
            { path: 'backups', name: 'Quản lý Sao lưu', component: () => import('../views/BackupManagement/Index.vue') },
        ]
    },
    {
        path: '/user',
        component: () => import('../layouts/EndUserLayout.vue'),
        meta: { requiresAuth: true, requiresEndUser: true },
        children: [
            { path: '', name: 'Bảng điều khiển User', component: () => import('../views/EndUser/Dashboard.vue') },
            { path: 'ekyc', name: 'Xác thực eKYC', component: () => import('../views/EndUser/EkycSubmit.vue') },
            { path: 'ntrip-accounts', name: 'Tài khoản NTRIP của tôi', component: () => import('../views/EndUser/NtripAccounts.vue') },
            { path: 'orders', name: 'Đơn hàng', component: () => import('../views/EndUser/Orders.vue') },
            { path: 'checkout', name: 'Thanh toán', component: () => import('../views/EndUser/Checkout.vue') },
            { path: 'payment-result', name: 'Kết quả thanh toán', component: () => import('../views/EndUser/PaymentResult.vue') },
            { path: 'profile', name: 'Hồ sơ cá nhân User', component: () => import('../views/Profile/Index.vue') },
            { path: 'support', name: 'Hỗ trợ kỹ thuật', component: () => import('../views/EndUser/Support/SupportList.vue') },
            { path: 'support/:id', name: 'Chi tiết yêu cầu hỗ trợ', component: () => import('../views/EndUser/Support/SupportDetail.vue') },
        ]
    },
    {
        path: '/gov',
        component: () => import('../layouts/GovernmentLayout.vue'),
        meta: { requiresAuth: true, requiresGov: true },
        children: [
            { path: 'dashboard', name: 'Tổng quan cơ quan', component: () => import('../views/Government/Dashboard.vue') },
            { path: 'stations', name: 'Giám sát trạm', component: () => import('../views/Government/Stations.vue') },
            { path: 'tickets', name: 'Lịch sử yêu cầu', component: () => import('../views/Government/Tickets.vue') },
            { path: 'profile', name: 'Hồ sơ cá nhân cơ quan', component: () => import('../views/Profile/Index.vue') },
        ]
    }
];

const router = createRouter({ history: createWebHistory(), routes });

router.beforeEach(async (to, _from) => {
    const authStore = useAuthStore();

    // Ensure profile is loaded if we have a token but no user object
    if (authStore.token && !authStore.user) {
        await authStore.fetchProfile();
    }

    const requiresAuth = to.matched.some(r => r.meta.requiresAuth);
    const requiresEndUser = to.matched.some(r => r.meta.requiresEndUser);
    const requiresGov = to.matched.some(r => r.meta.requiresGov);

    if (requiresAuth && !authStore.isAuthenticated) {
        return '/login';
    } else if (to.path === '/login' && authStore.isAuthenticated) {
        // Redirect based on role
        if (authStore.isAdmin) return '/';
        if (authStore.isGovernment) return '/gov/dashboard';
        if (authStore.isEndUser) return '/user';
        return '/';
    } else if (requiresAuth && authStore.isAuthenticated) {
        // Protect routes based on roles
        if (requiresEndUser && !authStore.isEndUser) {
            return authStore.isAdmin ? '/' : (authStore.isGovernment ? '/gov/dashboard' : '/');
        }
        if (requiresGov && !authStore.isGovernment) {
            return authStore.isAdmin ? '/' : (authStore.isEndUser ? '/user' : '/');
        }
        if (!requiresEndUser && !requiresGov && (authStore.isEndUser || authStore.isGovernment)) {
            return authStore.isEndUser ? '/user' : '/gov/dashboard';
        }
        return true;
    } else {
        return true;
    }
});

export default router;


