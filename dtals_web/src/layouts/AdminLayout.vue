<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthStore } from '../store/auth';
import { Expand, Fold, Loading } from '@element-plus/icons-vue';

const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const isCollapse = ref(false);
const isMobileScreen = ref(false);
const mobileMenuVisible = ref(false);

const isLoaded = computed(() => {
  if (!authStore.token) return true;
  return !!authStore.user;
});

const checkScreen = () => {
  isMobileScreen.value = window.innerWidth < 1024;
  if (!isMobileScreen.value) {
    mobileMenuVisible.value = false;
  }
};

onMounted(async () => {
  if (authStore.token && !authStore.user) {
    await authStore.fetchProfile();
  }
  checkScreen();
  window.addEventListener('resize', checkScreen);
});

const toggleSidebar = () => { 
  if (isMobileScreen.value) {
    mobileMenuVisible.value = !mobileMenuVisible.value;
  } else {
    isCollapse.value = !isCollapse.value; 
  }
};

const handleMenuClick = (path?: string) => {
  if (isMobileScreen.value) {
    mobileMenuVisible.value = false;
  }
  if (path) router.push(path);
};

const logout = () => {
  authStore.logout();
  router.push('/login');
};

const activeMenu = computed(() => route.path);

interface MenuItem {
  title: string;
  icon: string;
  path?: string;
  requiredPermissions?: string[];
  children?: MenuItem[];
}

const allMenuItems: MenuItem[] = [
  { title: 'BẢNG ĐIỀU KHIỂN', icon: '📊', path: '/' },
  {
    title: 'QUẢN LÝ TRẠM',
    icon: '📡',
    requiredPermissions: ['STATION_VIEW', 'STATION_MANAGE', 'STATION_CONTROL'],
    children: [
      { title: 'Bản đồ trạm', icon: '🗺️', path: '/stations/map', requiredPermissions: ['STATION_VIEW'] },
      { title: 'Danh sách trạm CORS', icon: '🏗️', path: '/stations', requiredPermissions: ['STATION_VIEW'] },
      { title: 'Yêu cầu từ CQNN', icon: '📝', path: '/tickets', requiredPermissions: ['STATION_VIEW'] },
    ]
  },
  {
    title: 'KHÁCH HÀNG',
    icon: '👥',
    requiredPermissions: ['USER_VIEW', 'USER_MANAGE', 'KYC_VIEW', 'KYC_MANAGE', 'CRM_VIEW', 'CRM_MANAGE'],
    children: [
      { title: 'Danh sách khách hàng', icon: '📱', path: '/users', requiredPermissions: ['USER_VIEW'] },
      { title: 'DS Tài khoản NTRIP', icon: '👤', path: '/ntrip-accounts', requiredPermissions: ['USER_VIEW'] },
      { title: 'Quản lý duyệt eKYC', icon: '🛡️', path: '/ekyc', requiredPermissions: ['KYC_VIEW', 'KYC_MANAGE'] },
      { title: 'Yêu cầu hỗ trợ', icon: '💬', path: '/support', requiredPermissions: ['USER_VIEW', 'CRM_VIEW', 'CRM_MANAGE'] },
    ]
  },
  {
    title: 'TÀI CHÍNH',
    icon: '💰',
    requiredPermissions: ['PAYMENT_VIEW', 'PAYMENT_MANAGE', 'REPORT_VIEW', 'SUBSCRIPTION_MANAGE'],
    children: [
      { title: 'Gói thuê bao', icon: '💎', path: '/ntrip-packages', requiredPermissions: ['SUBSCRIPTION_MANAGE'] },
      { title: 'Báo cáo doanh thu', icon: '📊', path: '/revenue-report', requiredPermissions: ['REPORT_VIEW'] },
    ]
  },
  {
    title: 'HỆ THỐNG',
    icon: '⚙️',
    requiredPermissions: ['ROLE_MANAGE', 'USER_MANAGE', 'NOTIFICATION_MANAGE'],
    children: [
      { title: 'Nhân viên', icon: '🪪', path: '/system-users', requiredPermissions: ['USER_MANAGE'] },
      { title: 'Phân quyền', icon: '🔑', path: '/system/roles', requiredPermissions: ['ROLE_MANAGE'] },
      { title: 'Cấu hình xác thực', icon: '🔐', path: '/system/auth-config', requiredPermissions: ['ROLE_MANAGE'] },
      { title: 'Cấu hình thanh toán', icon: '💳', path: '/system/payos-config', requiredPermissions: ['PAYMENT_MANAGE'] },
      { title: 'Quản lý Sao lưu', icon: '💾', path: '/backups', requiredPermissions: ['ROLE_MANAGE'] },
    ]
  },
];

const canAccess = (item: MenuItem): boolean => {
  if (!item.requiredPermissions || item.requiredPermissions.length === 0) return true;
  return authStore.hasAnyPermission(...item.requiredPermissions);
};

const filteredMenuItems = computed(() => {
  return allMenuItems
    .filter(item => canAccess(item))
    .map(item => {
      if (!item.children) return item;
      const visibleChildren = item.children.filter(child => canAccess(child));
      if (visibleChildren.length === 0) return null;
      return { ...item, children: visibleChildren };
    })
    .filter(Boolean) as MenuItem[];
});
</script>

<template>
  <div v-if="isLoaded" class="flex h-screen w-full overflow-hidden bg-[#f4f6f9]">
    <!-- Mobile Sidebar Drawer -->
    <el-drawer
      v-model="mobileMenuVisible"
      direction="ltr"
      size="280px"
      :with-header="false"
      class="mobile-sidebar-drawer"
    >
      <div class="sidebar-container h-full flex flex-col bg-[#343a40]">
        <!-- Brand -->
        <div class="brand-link flex items-center h-[70px] px-5 bg-[#3d444b] border-b border-gray-700">
          <div class="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center mr-3 shadow-lg">
            <span class="text-white font-bold text-xl">D</span>
          </div>
          <span class="text-white font-bold text-lg tracking-wider">DTALS</span>
        </div>
        <el-scrollbar class="flex-1">
          <el-menu 
            :default-active="activeMenu" 
            background-color="transparent" 
            text-color="#c2c7d0"
            active-text-color="#ffffff" 
            class="border-none custom-sidebar-menu mt-4" 
            router 
            unique-opened
            @select="handleMenuClick"
          >
            <template v-for="item in filteredMenuItems" :key="item.title">
              <el-menu-item v-if="!item.children" :index="item.path">
                <span class="w-8 text-center text-[18px] mr-2">{{ item.icon }}</span>
                <template #title><span class="text-[13px] font-medium tracking-wide">{{ item.title }}</span></template>
              </el-menu-item>
              <el-sub-menu v-else :index="item.title">
                <template #title>
                  <span class="w-8 text-center text-[18px] mr-2">{{ item.icon }}</span>
                  <span class="text-[13px] font-medium tracking-wide">{{ item.title }}</span>
                </template>
                <el-menu-item v-for="child in item.children" :key="child.path" :index="child.path">
                  <span class="w-6 text-center text-[15px] mr-2 ml-2 opacity-80">{{ child.icon }}</span>
                  <template #title><span class="text-[13px]">{{ child.title }}</span></template>
                </el-menu-item>
              </el-sub-menu>
            </template>
          </el-menu>
        </el-scrollbar>
      </div>
    </el-drawer>

    <!-- Sidebar (Desktop style) -->
    <aside 
      v-if="!isMobileScreen"
      :class="['h-full bg-[#343a40] transition-all duration-300 shadow-xl z-[1001] flex-shrink-0', isCollapse ? 'w-[64px]' : 'w-[250px]']"
    >
      <div class="sidebar-container h-full flex flex-col bg-[#343a40]">
        <!-- Brand -->
        <div class="brand-link flex items-center h-[70px] px-5 bg-[#3d444b] border-b border-gray-700">
          <div class="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center mr-3 shadow-lg">
            <span class="text-white font-bold text-xl">D</span>
          </div>
          <span v-if="!isCollapse" class="text-white font-bold text-lg tracking-wider">
            DTALS <small class="font-light opacity-50">v1</small>
          </span>
        </div>

        <!-- Menu -->
        <el-scrollbar class="flex-1">
          <el-menu :default-active="activeMenu" background-color="transparent" text-color="#c2c7d0"
            active-text-color="#ffffff" class="border-none custom-sidebar-menu mt-4" router unique-opened
            :collapse="isCollapse" :collapse-transition="false">
            <template v-for="item in filteredMenuItems" :key="item.title">
              <el-menu-item v-if="!item.children" :index="item.path">
                <span class="w-8 text-center text-[18px] mr-2">{{ item.icon }}</span>
                <template #title><span class="text-[13px] font-medium tracking-wide">{{ item.title }}</span></template>
              </el-menu-item>
              
              <el-sub-menu v-else :index="item.title">
                <template #title>
                  <span class="w-8 text-center text-[18px] mr-2">{{ item.icon }}</span>
                  <span class="text-[13px] font-medium tracking-wide">{{ item.title }}</span>
                </template>
                <el-menu-item v-for="child in item.children" :key="child.path" :index="child.path">
                  <span class="w-6 text-center text-[15px] mr-2 ml-2 opacity-80">{{ child.icon }}</span>
                  <template #title><span class="text-[13px]">{{ child.title }}</span></template>
                </el-menu-item>
              </el-sub-menu>
            </template>
          </el-menu>
        </el-scrollbar>

        <div class="p-4 border-t border-gray-700 text-[10px] text-gray-500 text-center uppercase">
          DTALS Admin © 2026
        </div>
      </div>
    </aside>

    <!-- Main content area -->
    <div class="flex flex-col flex-1 min-w-0 overflow-hidden">
      <!-- Header -->
      <header class="h-[64px] w-full bg-white border-b z-[1000] sticky top-0 flex-shrink-0 shadow-sm flex items-center">
        <div class="px-4 cursor-pointer text-gray-500 hover:text-blue-600 transition-colors" @click="toggleSidebar">
          <el-icon :size="24">
            <Expand v-if="isCollapse" />
            <Fold v-else />
          </el-icon>
        </div>
        <div class="flex-1 px-4">
          <span class="text-lg font-semibold text-gray-700">{{ route.name }}</span>
        </div>
        <div class="flex items-center gap-4 pr-6">
          <el-dropdown trigger="click">
            <div class="flex items-center gap-2 cursor-pointer text-gray-600 hover:text-blue-500 transition-colors">
              <div class="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white text-sm font-bold">
                {{ authStore.user?.username?.charAt(0)?.toUpperCase() || 'A' }}
              </div>
              <span class="text-sm">{{ authStore.user?.username || 'Admin' }}</span>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="$router.push('/profile')">👤 Hồ sơ cá nhân</el-dropdown-item>
                <el-dropdown-item divided @click="logout">🚪 Đăng xuất</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <!-- Main -->
      <main class="flex-1 overflow-y-auto p-6 scroll-smooth bg-[#f4f6f9]">
        <div class="mx-auto w-full max-w-[1600px]">
          <router-view />
        </div>
        <footer class="mt-8 py-4 border-t border-gray-200 text-center text-xs text-gray-400">
          <strong>DTALS Web Admin</strong> &copy; 2026. Phát triển bởi <b>Zenpos Team</b>.
        </footer>
      </main>
    </div>
  </div>

  <!-- Loading state while fetching profile -->
  <div v-else class="h-screen w-screen flex flex-col items-center justify-center bg-[#f4f6f9]">
    <el-icon class="is-loading text-blue-500" :size="45">
      <Loading />
    </el-icon>
    <p class="mt-4 text-gray-600 font-medium animate-pulse text-sm">
      Đang đồng bộ dữ liệu hệ thống...
    </p>
  </div>
</template>

<style scoped>
aside { transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
.flex-1 { min-width: 0; }

/* Sidebar Menu Customization */
:deep(.custom-sidebar-menu) {
  --el-menu-bg-color: transparent;
  --el-menu-hover-bg-color: rgba(255, 255, 255, 0.05);
  border-right: none;
}
:deep(.custom-sidebar-menu .el-menu-item),
:deep(.custom-sidebar-menu .el-sub-menu__title) {
  margin: 4px 12px;
  border-radius: 8px;
  height: 44px;
  line-height: 44px;
  color: #c2c7d0;
}
:deep(.custom-sidebar-menu .el-menu-item.is-active) {
  background-color: #3b82f6 !important; /* Tailwind blue-500 */
  color: #ffffff !important;
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.4), 0 2px 4px -1px rgba(59, 130, 246, 0.2);
}
:deep(.custom-sidebar-menu .el-menu-item:hover),
:deep(.custom-sidebar-menu .el-sub-menu__title:hover) {
  color: #ffffff;
}
/* Submenu adjustment */
:deep(.custom-sidebar-menu .el-sub-menu .el-menu) {
  padding: 4px 0;
  background-color: transparent;
}
:deep(.custom-sidebar-menu .el-sub-menu .el-menu-item) {
  height: 40px;
  line-height: 40px;
  margin: 2px 12px 2px 24px;
}

:deep(.mobile-sidebar-drawer) {
  background-color: #343a40;
}
:deep(.mobile-sidebar-drawer .el-drawer__body) {
  padding: 0;
  background-color: #343a40;
}

@media (max-width: 1023px) {
  main {
    padding: 16px !important;
  }
  header .text-lg {
    font-size: 14px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 150px;
  }
}
</style>
