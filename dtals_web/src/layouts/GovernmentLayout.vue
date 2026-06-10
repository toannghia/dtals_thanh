<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthStore } from '../store/auth';
import { Expand, Fold, Loading } from '@element-plus/icons-vue';

const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const isCollapse = ref(false);

const isLoaded = computed(() => {
  if (!authStore.token) return true;
  return !!authStore.user;
});

onMounted(async () => {
  if (authStore.token && !authStore.user) {
    await authStore.fetchProfile();
  }
});

const toggleSidebar = () => { isCollapse.value = !isCollapse.value; };

const logout = () => {
  authStore.logout();
  router.push('/login');
};

const activeMenu = computed(() => route.path);

interface MenuItem {
  title: string;
  icon: string;
  path?: string;
  children?: MenuItem[];
}

const menuItems: MenuItem[] = [
  { title: 'TỔNG QUAN', icon: '📊', path: '/gov/dashboard' },
  { title: 'GIÁM SÁT TRẠM', icon: '📡', path: '/gov/stations' },
  { title: 'YÊU CẦU ĐIỀU KHIỂN', icon: '📝', path: '/gov/tickets' },
];
</script>

<template>
  <div v-if="isLoaded" class="flex h-screen w-full overflow-hidden bg-[#f4f6f9]">
    <!-- Sidebar -->
    <aside :class="['h-full bg-[#1e293b] transition-all duration-300 shadow-xl z-[1001] flex-shrink-0', isCollapse ? 'w-[64px]' : 'w-[250px]']">
      <div class="sidebar-container h-full flex flex-col">
        <!-- Brand -->
        <div class="brand-link flex items-center h-[70px] px-5 bg-slate-800/50 border-b border-slate-700/50">
          <div class="w-8 h-8 bg-emerald-500 rounded-lg flex items-center justify-center mr-3 shadow-lg">
            <span class="text-white font-bold text-xl">G</span>
          </div>
          <span v-if="!isCollapse" class="text-white font-bold text-lg tracking-wider">
            GOV PORTAL
          </span>
        </div>

        <!-- Menu -->
        <el-scrollbar class="flex-1">
          <el-menu :default-active="activeMenu" background-color="transparent" text-color="#94a3b8"
            active-text-color="#ffffff" class="border-none custom-sidebar-menu mt-4" router unique-opened
            :collapse="isCollapse" :collapse-transition="false">
            <template v-for="item in menuItems" :key="item.title">
              <el-menu-item :index="item.path">
                <span class="w-8 text-center text-[18px] mr-2">{{ item.icon }}</span>
                <template #title><span class="text-[13px] font-medium tracking-wide">{{ item.title }}</span></template>
              </el-menu-item>
            </template>
          </el-menu>
        </el-scrollbar>

        <div class="p-4 border-t border-slate-700/50 text-[10px] text-slate-500 text-center uppercase">
          Gov Dashboard © 2026
        </div>
      </div>
    </aside>

    <!-- Main content area -->
    <div class="flex flex-col flex-1 min-w-0 overflow-hidden">
      <!-- Header -->
      <header class="h-[64px] w-full bg-white border-b z-[1000] sticky top-0 flex-shrink-0 shadow-sm flex items-center">
        <div class="px-4 cursor-pointer text-gray-500 hover:text-emerald-600 transition-colors" @click="toggleSidebar">
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
            <div class="flex items-center gap-2 cursor-pointer text-gray-600 hover:text-emerald-500 transition-colors">
              <div class="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center text-white text-sm font-bold">
                {{ authStore.user?.username?.charAt(0)?.toUpperCase() || 'G' }}
              </div>
              <span class="text-sm">{{ authStore.user?.username || 'Cơ quan nhà nước' }}</span>
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
      <main class="flex-1 overflow-y-auto p-6 scroll-smooth bg-[#f8fafc]">
        <div class="mx-auto w-full max-w-[1600px]">
          <router-view />
        </div>
      </main>
    </div>
  </div>

  <!-- Loading state -->
  <div v-else class="h-screen w-screen flex flex-col items-center justify-center bg-[#f4f6f9]">
    <el-icon class="is-loading text-emerald-500" :size="45">
      <Loading />
    </el-icon>
    <p class="mt-4 text-gray-600 font-medium animate-pulse text-sm">
      Đang tải cổng thông tin cơ quan...
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
:deep(.custom-sidebar-menu .el-menu-item) {
  margin: 4px 12px;
  border-radius: 8px;
  height: 44px;
  line-height: 44px;
  color: #94a3b8;
}
:deep(.custom-sidebar-menu .el-menu-item.is-active) {
  background-color: #10b981 !important; /* Emerald-500 */
  color: #ffffff !important;
  box-shadow: 0 4px 6px -1px rgba(16, 185, 129, 0.4), 0 2px 4px -1px rgba(16, 185, 129, 0.2);
}
:deep(.custom-sidebar-menu .el-menu-item:hover) {
  color: #ffffff;
}
</style>
