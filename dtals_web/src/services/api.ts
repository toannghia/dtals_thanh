import axios from 'axios';
import { useAuthStore } from '../store/auth';

const api = axios.create({
    baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000',
    timeout: 15000,
});

api.interceptors.request.use((config) => {
    const authStore = useAuthStore();
    if (authStore.token) {
        config.headers.Authorization = `Bearer ${authStore.token}`;
    }
    return config;
});

api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            const authStore = useAuthStore();
            // Only logout if the user was previously authenticated (expired token).
            // Don't logout during login attempts (where 401 = wrong password).
            if (authStore.token && !error.config?.url?.includes('/auth/login')) {
                authStore.logout();
            }
        }
        return Promise.reject(error);
    }
);

// ---- Auth ----
export const authApi = {
    login: (username: string, password: string, captchaToken?: string) =>
        api.post('/auth/login', { username, password, captchaToken }),
    getProfile: () => api.get('/auth/profile'),
    updateProfile: (data: { fullName?: string; avatar?: string; email?: string; phoneNumber?: string }) =>
        api.put('/auth/profile', data),
};

// ---- Dashboard ----
export const dashboardApi = {
    getStationStats: () => api.get('/dtals-dashboard/stations'),
    getUserStats: () => api.get('/dtals-dashboard/users'),
    getOverview: () => api.get('/dtals-dashboard/overview'),
};

// ---- Stations ----
export const stationApi = {
    getStations: (params?: { page?: number; size?: number; stationName?: string; status?: number; connectStatus?: number }) =>
        api.get('/stations', { params }),
    getDynamicInfo: (ids: number[]) =>
        api.post('/stations/dynamic-info', { ids }),
    getSatellites: (id: number) =>
        api.get(`/stations/${id}/satellites`),
};

// ---- NTRIP Users ----
export const ntripUserApi = {
    list: (params?: { page?: number; size?: number; keywords?: string; enabled?: number; name?: string }) =>
        api.get('/ntrip-users', { params }),
    create: (data: {
        name: string;
        userPwd: string;
        startTime?: number;
        endTime?: number;
        enabled?: number;
        numOnline?: number;
        casterIds?: number[];
        mountIds?: number[];
    }) => api.post('/ntrip-users', data),
    update: (id: string | number, data: {
        name?: string;
        userPwd?: string;
        startTime?: number;
        endTime?: number;
        enabled?: number;
        numOnline?: number;
        casterIds?: number[];
        mountIds?: number[];
    }) => api.put(`/ntrip-users/${id}`, data),
    toggle: (id: string | number, enabled: number) =>
        api.patch(`/ntrip-users/${id}/toggle`, { enabled }),
    delete: (ids: (string | number)[]) =>
        api.post('/ntrip-users/delete', { ids }),
};

// ---- Online Users ----
export const onlineUserApi = {
    getOnlineUsers: (params?: { page?: number; size?: number }) =>
        api.get('/online-users', { params }),
};

// ---- Admin Users (System) ----
export const adminUserApi = {
    list: (params?: { page?: number; limit?: number; search?: string }) =>
        api.get('/users', { params }),
    create: (data: any) =>
        api.post('/users', data),
    update: (id: string | number, data: any) =>
        api.put(`/users/${id}`, data),
    delete: (id: string | number) =>
        api.delete(`/users/${id}`),
};

// ---- Admin End Users ----
export const adminEndUserApi = {
    list: (params?: { page?: number; limit?: number; search?: string; status?: string }) =>
        api.get('/admin/end-users', { params }),
    getDetail: (id: string) =>
        api.get(`/admin/end-users/${id}`),
    update: (id: string, data: any) =>
        api.put(`/admin/end-users/${id}`, data),
    updateStatus: (id: string, status: string) =>
        api.put(`/admin/end-users/${id}/status`, { status }),
    activate: (id: string) =>
        api.put(`/admin/end-users/${id}/activate`),
    softDelete: (id: string) =>
        api.delete(`/admin/end-users/${id}`),
};

// ---- Admin eKYC ----
export const adminEkycApi = {
    list: (params?: { page?: number; limit?: number; status?: string }) =>
        api.get('/ekyc/admin/submissions', { params }),
    getDetail: (id: string) =>
        api.get(`/ekyc/admin/submissions/${id}`),
    review: (id: string, data: { status: string; reviewNote?: string; faceMatchScore?: number }) =>
        api.put(`/ekyc/admin/submissions/${id}/review`, data),
    delete: (id: string) =>
        api.delete(`/ekyc/admin/submissions/${id}`),
};

// ---- End User Auth ----
export const endUserAuthApi = {
    register: (data: any) => api.post('/auth/register', data),
    activate: (token: string) => api.get('/auth/activate', { params: { token } }),
    forgotPasswordInit: (data: any) => api.post('/auth/forgot-password/init', data),
    resetPassword: (data: any) => api.post('/auth/reset-password', data),
};

// ---- eKYC (End User) ----
export const ekycApi = {
    getStatus: () => api.get('/ekyc/status'),
    submit: (formData: FormData) => api.post('/ekyc/submit', formData, {
        headers: {
            'Content-Type': 'multipart/form-data'
        }
    }),
};

// ---- Packages (Public + Admin) ----
export const packageApi = {
    listActive: () => api.get('/ntrip-packages/active'),
    listAll: () => api.get('/ntrip-packages'),
    create: (data: any) => api.post('/ntrip-packages', data),
    update: (id: number, data: any) => api.put(`/ntrip-packages/${id}`, data),
    delete: (id: number) => api.delete(`/ntrip-packages/${id}`),
};

// ---- Orders (End User) ----
export const orderApi = {
    list: (params?: { status?: string }) => api.get('/orders', { params }),
    create: (data: { ntripAccountName: string; ntripPassword: string; packageId: number; quantity?: number; startTime?: number }) => api.post('/orders', data),
    checkout: (orderIds: number[]) => api.post('/payment/checkout', { orderIds }),
    cancel: (id: number) => api.post(`/orders/${id}/cancel`),
    getDetail: (id: number) => api.get(`/orders/${id}`),
};

// ---- Payment (PayOS) ----
export const paymentApi = {
    syncStatus: (orderCode: string) => api.get(`/payment/sync/${orderCode}`),
};

// ---- Admin Roles ----
export const adminRoleApi = {
    list: () => api.get('/admin/roles'),
    getPermissions: () => api.get('/admin/roles/permissions'),
    create: (data: { name: string; permissions: string[] }) =>
        api.post('/admin/roles', data),
    update: (id: string, data: { name?: string; permissions?: string[] }) =>
        api.put(`/admin/roles/${id}`, data),
    delete: (id: string) => api.delete(`/admin/roles/${id}`),
};

// ---- Admin Auth Config ----
export const adminAuthConfigApi = {
    get: () => api.get('/admin/auth-config'),
    update: (data: {
        activeProvider: string;
        maxOtpPerHour: number;
        fallbackEnabled: boolean;
        firebaseConfig?: any;
        emailConfig?: any;
    }) => api.put('/admin/auth-config', data),
};

// ---- Admin PayOS Config ----
export const adminPayosConfigApi = {
    get: () => api.get('/admin/payos-config'),
    update: (data: {
        clientId?: string;
        apiKey?: string;
        checksumKey?: string;
        partnerCode?: string;
        returnUrl?: string;
        cancelUrl?: string;
        webhookUrl?: string;
        isSandbox?: boolean;
        isEnabled?: boolean;
    }) => api.put('/admin/payos-config', data),
};

// ---- Admin Revenue Report ----
export const revenueReportApi = {
    getSummary: (params: { startDate: string; endDate: string }) => api.get('/admin/revenue/summary', { params }),
    getChart: (params: { startDate: string; endDate: string }) => api.get('/admin/revenue/chart', { params }),
    getDetails: (params: { startDate: string; endDate: string; page?: number; limit?: number }) =>
        api.get('/admin/revenue/details', { params }),
    export: (params: { startDate: string; endDate: string }) =>
        api.get('/admin/revenue/export', { params, responseType: 'blob' }),
};

// ---- Government Portal ----
export const governmentApi = {
    getDashboard: () => api.get('/government/dashboard'),
    getStations: () => api.get('/government/stations'),
    createTicket: (data: { subject: string; type?: string; stationId?: number; reason: string }) =>
        api.post('/government/tickets', data),
    getTickets: () => api.get('/government/tickets'),
};

// ---- Tickets (Admin + General) ----
export const ticketApi = {
    list: () => api.get('/tickets'),
    getDetail: (id: string) => api.get(`/tickets/${id}`),
    updateStatus: (id: string, data: { status: string; adminNote?: string }) =>
        api.patch(`/tickets/${id}/status`, data),
};

// ---- Support (End User) ----
export const supportApi = {
    list: (params?: { page?: number; limit?: number }) => api.get('/support', { params }),
    getMessages: (id: string) => api.get(`/support/${id}/messages`),
    create: (formData: FormData) => api.post('/support', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
    }),
    addMessage: (id: string, formData: FormData) => api.post(`/support/${id}/messages`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
    }),
};

// ---- Administrator Support (Admin) ----
export const adminSupportApi = {
    list: (params?: { page?: number; limit?: number; status?: string }) => api.get('/admin/support', { params }),
    getMessages: (id: string) => api.get(`/admin/support/${id}/messages`),
    updateStatus: (id: string, status: string) => api.patch(`/admin/support/${id}/status`, { status }),
    addMessage: (id: string, formData: FormData) => api.post(`/admin/support/${id}/messages`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
    }),
};

// ---- Administrator Backup (Admin) ----
export const backupApi = {
    list: (params?: { page?: number; limit?: number }) => api.get('/admin/backups', { params }),
    runBackup: () => api.post('/admin/backups/run'),
    getConfig: () => api.get('/admin/backups/config'),
    updateConfig: (data: { cronTime: string; keepDays: number }) => api.put('/admin/backups/config', data),
};

// ---- CRM Activities & Notes (Admin) ----
export const crmApi = {
    listActivities: (params?: { userId?: string; type?: string; status?: string; page?: number; limit?: number }) =>
        api.get('/admin/crm/activities', { params }),
    createActivity: (data: {
        type: string; title: string; userId: string;
        description?: string; priority?: string; status?: string;
        scheduledAt?: string; dueDate?: string; assignedToId?: string;
        metadata?: Record<string, any>;
    }) => api.post('/admin/crm/activities', data),
    updateActivity: (id: string, data: any) =>
        api.put(`/admin/crm/activities/${id}`, data),
    deleteActivity: (id: string) =>
        api.delete(`/admin/crm/activities/${id}`),
    listNotes: (params?: { userId?: string }) =>
        api.get('/admin/crm/notes', { params }),
    createNote: (data: { userId: string; content: string; isPinned?: boolean }) =>
        api.post('/admin/crm/notes', data),
    updateNote: (id: string, data: { content?: string; isPinned?: boolean }) =>
        api.put(`/admin/crm/notes/${id}`, data),
    deleteNote: (id: string) =>
        api.delete(`/admin/crm/notes/${id}`),
    getStats: (userId: string) =>
        api.get('/admin/crm/stats', { params: { userId } }),
};

export default api;
