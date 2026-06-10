import { defineStore } from 'pinia';
import { authApi } from '../services/api';

interface UserProfile {
    id: number;
    username: string;
    role: string;
    permissions?: string[];
    email?: string;
    fullName?: string;
    full_name?: string;
    phoneNumber?: string;
    avatar?: string;
    roleName?: string;
    kycStatus?: string;
}

export const useAuthStore = defineStore('auth', {
    state: () => ({
        token: localStorage.getItem('access_token') || '',
        user: null as UserProfile | null,
    }),
    getters: {
        isAuthenticated: (state) => !!state.token,
        isAdmin: (state) => {
            const r = state.user?.role?.toUpperCase();
            return r === 'ADMIN' || r === 'SUPERADMIN' || r === 'SUPER_ADMIN';
        },
        isSuperUser: (state) => {
            return state.user?.permissions?.includes('ALL') || false;
        },
        isEndUser: (state) => state.user?.role?.toUpperCase() === 'END_USER',
        isGovernment: (state) => {
            const r = state.user?.role?.toUpperCase();
            return r === 'GOV' || r === 'AUTHORITY';
        },
    },
    actions: {
        hasPermission(permission: string): boolean {
            if (!this.user?.permissions) return false;
            if (this.user.permissions.includes('ALL')) return true;
            return this.user.permissions.includes(permission);
        },
        hasAnyPermission(...permissions: string[]): boolean {
            if (!this.user?.permissions) return false;
            if (this.user.permissions.includes('ALL')) return true;
            return permissions.some(p => this.user!.permissions!.includes(p));
        },
        async login(username: string, password: string, captchaToken?: string) {
            const res = await authApi.login(username, password, captchaToken);
            this.token = res.data.access_token;
            localStorage.setItem('access_token', this.token);
            await this.fetchProfile();
        },
        async fetchProfile() {
            try {
                const res = await authApi.getProfile();
                const data = res.data;
                // Normalize: /auth/profile returns role as an object {name, permissions}
                const roleObj = typeof data.role === 'object' ? data.role : null;
                this.user = {
                    ...data,
                    role: roleObj ? roleObj.name : data.role,
                    permissions: roleObj?.permissions || data.permissions || [],
                };
            } catch {
                this.logout();
            }
        },
        setAuth(token: string, user: UserProfile) {
            this.token = token;
            this.user = user;
            localStorage.setItem('access_token', token);
        },
        logout() {
            this.token = '';
            this.user = null;
            localStorage.removeItem('access_token');
        },
    },
});
