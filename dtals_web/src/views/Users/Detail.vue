<template>
  <div class="user-crm-detail min-h-screen bg-gray-50/50 -m-6 p-6">
    <div class="mb-6 flex justify-between items-center">
      <div class="flex items-center gap-3">
        <el-button @click="$router.push('/users')">Quay lại</el-button>
        <h2 class="text-2xl font-bold text-gray-800 m-0">Chi tiết Khách hàng</h2>
      </div>
      <div>
        <!-- Action buttons could go here -->
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center items-center h-64">
      <el-spinner size="50px" />
    </div>

    <div v-else-if="user" class="grid grid-cols-1 md:grid-cols-12 gap-6">
      
      <!-- Lệft Column: User Info Card -->
      <div class="md:col-span-4 lg:col-span-3 space-y-6">
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100/50 relative overflow-hidden pb-6 text-center">
          <div class="bg-gradient-to-br from-blue-500 to-purple-600 h-24 w-full absolute top-0 left-0 z-0"></div>
          <div class="relative z-10 pt-12">
            <el-avatar :size="96" :src="user.avatar || 'https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png'" class="border-4 border-white shadow-md mx-auto bg-white" />
            <h3 class="mt-4 text-xl font-bold text-gray-800">{{ user.fullName || user.username }}</h3>
            <p class="text-gray-500 text-sm">@{{ user.username }}</p>
            
            <div class="mt-3">
              <el-tag :type="user.status === 'ACTIVE' ? 'success' : 'danger'" effect="dark" round>
                {{ user.status === 'ACTIVE' ? 'Đang hoạt động' : 'Tạm khóa' }}
              </el-tag>
            </div>
          </div>

          <el-divider class="!my-4" />
          
          <div class="px-6 text-left text-sm space-y-4">
            <div class="flex items-center gap-3 text-gray-600">
              <el-icon class="text-blue-500"><Message /></el-icon>
              <span class="truncate">{{ user.email || 'Chưa cung cấp' }}</span>
            </div>
            <div class="flex items-center gap-3 text-gray-600">
              <el-icon class="text-green-500"><Phone /></el-icon>
              <span>{{ user.phoneNumber || 'Chưa cung cấp' }}</span>
            </div>
            <div class="flex items-center gap-3 text-gray-600">
              <el-icon class="text-orange-500"><Calendar /></el-icon>
              <span>Gia nhập: {{ formatDate(user.createdAt) }}</span>
            </div>
            <div class="flex items-center gap-3 text-gray-600">
              <el-icon :class="user.kycStatus === 'VERIFIED' ? 'text-green-500' : 'text-gray-400'"><Checked /></el-icon>
              <span class="font-medium" :class="user.kycStatus === 'VERIFIED' ? 'text-green-600' : 'text-gray-500'">KYC: {{ user.kycStatus }}</span>
            </div>
          </div>
          
          <div class="mt-6 px-6">
            <el-button type="primary" plain class="w-full" @click="handleToggleStatus">
              {{ user.status === 'ACTIVE' ? 'Khóa Tài Khoản' : 'Mở Khóa Tài Khoản' }}
            </el-button>
          </div>
        </div>

        <!-- Stats Overview -->
        <div class="grid grid-cols-2 gap-4">
          <div class="bg-white p-4 rounded-2xl shadow-sm border border-gray-100/50 flex flex-col items-center justify-center">
            <span class="text-3xl font-bold text-blue-600">{{ ntripAccounts.length }}</span>
            <span class="text-xs text-gray-500 mt-1 text-center">Tài khoản NTRIP</span>
          </div>
          <div class="bg-white p-4 rounded-2xl shadow-sm border border-gray-100/50 flex flex-col items-center justify-center">
            <span class="text-3xl font-bold text-green-600">{{ user.orders?.length || 0 }}</span>
            <span class="text-xs text-gray-500 mt-1 text-center">Đơn hàng</span>
          </div>
          <div class="bg-white p-4 rounded-2xl shadow-sm border border-gray-100/50 flex flex-col items-center justify-center col-span-2">
            <span class="text-2xl font-bold text-purple-600">{{ formatPrice(totalSpent) }}</span>
            <span class="text-xs text-gray-500 mt-1 text-center">Tổng chi tiêu</span>
          </div>
        </div>
      </div>

      <!-- Right Column: Tabs -->
      <div class="md:col-span-8 lg:col-span-9">
        <el-card shadow="never" class="border-0 rounded-2xl overflow-hidden min-h-[500px]">
          <el-tabs v-model="activeTab" class="dashboard-tabs">
            
            <!-- Tab: NTRIP Accounts -->
            <el-tab-pane label="Tài khoản NTRIP" name="ntrip">
              <div class="p-2">
                <el-table :data="ntripAccounts" stripe v-loading="loadingNtrip">
                  <el-table-column prop="name" label="Tên tài khoản (Mountpoint)" min-width="180">
                    <template #default="{ row }">
                      <span class="font-medium text-blue-700">{{ row.name }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="Kết nối" width="100" align="center">
                    <template #default="{ row }">
                      <el-tag type="info" size="small">{{ row.numOnline || 1 }} ĐT</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="Trạng thái sử dụng" min-width="180">
                    <template #default="{ row }">
                      <div class="flex flex-col">
                        <span v-if="row.endTime" class="text-sm">
                          Hết hạn: <span :class="isExpired(row.endTime) ? 'text-red-500 font-bold' : ''">{{ formatDate(row.endTime) }}</span>
                        </span>
                        <span v-else class="text-gray-400 text-sm">Chưa có hạn</span>
                        <span v-if="row.endTime && !isExpired(row.endTime)" class="text-xs text-orange-500 mt-1">
                          Còn {{ daysLeft(row.endTime) }} ngày
                        </span>
                        <span v-else-if="isExpired(row.endTime)" class="text-xs text-red-500 mt-1">Đã hết hạn</span>
                      </div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Trạng thái bật/tắt" width="150" align="center">
                    <template #default="{ row }">
                      <el-tag :type="row.enabled === 1 ? 'success' : 'danger'">
                        {{ row.enabled === 1 ? 'Đang hoạt động' : 'Tạm dừng' }}
                      </el-tag>
                    </template>
                  </el-table-column>
                </el-table>
                <div v-if="!loadingNtrip && ntripAccounts.length === 0" class="text-center py-8 text-gray-400">
                  Khách hàng chưa sở hữu tài khoản NTRIP nào.
                </div>
              </div>
            </el-tab-pane>

            <!-- Tab: Đơn hàng -->
            <el-tab-pane label="Lịch sử Mua hàng" name="orders">
              <div class="p-2">
                <el-table :data="user.orders" stripe>
                  <el-table-column prop="id" label="Mã ĐH" width="100">
                    <template #default="{ row }">
                      #{{ row.id }}
                    </template>
                  </el-table-column>
                  <el-table-column label="Dịch vụ" min-width="200">
                    <template #default="{ row }">
                      <div class="font-medium">{{ row.packageName }}</div>
                      <div class="text-xs text-gray-500 mt-1">Gia hạn cho: {{ row.ntripAccountName }}</div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Tổng tiền" width="150" align="right">
                    <template #default="{ row }">
                      <span class="font-medium">{{ formatPrice(row.amount) }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="Thời gian" width="160" align="center">
                    <template #default="{ row }">
                      <div class="text-sm">{{ formatDate(row.createdAt) }}</div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Trạng thái" width="180" align="center">
                    <template #default="{ row }">
                      <div class="flex items-center justify-center gap-2">
                        <el-tag v-if="row.status === 'PAID'" type="success" size="small">Đã TT</el-tag>
                        <el-tag v-else-if="row.status === 'PENDING'" type="warning" size="small">Chờ TT</el-tag>
                        <el-tag v-else type="info" size="small">Đã Hủy</el-tag>

                        <el-tooltip v-if="row.status === 'PENDING' && row.payosOrderCode" content="Đồng bộ thủ công với PayOS">
                          <el-button 
                            size="small" 
                            circle 
                            plain 
                            type="primary" 
                            :icon="RefreshRight"
                            :loading="syncing[row.id]"
                            @click="handleSyncPayment(row)"
                          />
                        </el-tooltip>
                      </div>
                    </template>
                  </el-table-column>
                </el-table>
              </div>
            </el-tab-pane>

            <!-- Tab: Hỗ trợ -->
            <el-tab-pane label="Yêu cầu hỗ trợ" name="support">
              <div class="p-2">
                <el-table :data="user.supportTickets" stripe>
                  <el-table-column label="Tiêu đề" min-width="200">
                    <template #default="{ row }">
                      <router-link :to="`/support/${row.id}`" class="text-blue-600 hover:underline font-medium block truncate">
                        {{ row.subject }}
                      </router-link>
                    </template>
                  </el-table-column>
                  <el-table-column label="Phân loại" width="150">
                    <template #default="{ row }">
                      {{ row.type || 'Hỗ trợ kỹ thuật' }}
                    </template>
                  </el-table-column>
                  <el-table-column label="Ngày gửi" width="160" align="center">
                    <template #default="{ row }">
                      <div class="text-sm">{{ formatDate(row.createdAt) }}</div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Trạng thái" width="130" align="center">
                    <template #default="{ row }">
                      <el-tag :type="getStatusType(row.status)" size="small">{{ formatStatus(row.status) }}</el-tag>
                    </template>
                  </el-table-column>
                </el-table>
                <div v-if="(!user.supportTickets || user.supportTickets.length === 0)" class="text-center py-8 text-gray-400">
                  Khách hàng chưa gửi yêu cầu hỗ trợ nào.
                </div>
              </div>
            </el-tab-pane>

            <!-- Tab: Chăm sóc KH -->
            <el-tab-pane label="Chăm sóc KH" name="crm">
              <div class="p-2">
                <!-- Mini Stats -->
                <div class="grid grid-cols-4 gap-3 mb-5">
                  <div class="bg-blue-50 border border-blue-100 rounded-xl p-3 text-center">
                    <span class="text-2xl font-bold text-blue-600">{{ crmStats.pendingTasks }}</span>
                    <div class="text-xs text-blue-500 mt-1">📋 Tasks chờ</div>
                  </div>
                  <div class="bg-green-50 border border-green-100 rounded-xl p-3 text-center">
                    <span class="text-2xl font-bold text-green-600">{{ crmStats.totalCalls }}</span>
                    <div class="text-xs text-green-500 mt-1">📞 Cuộc gọi</div>
                  </div>
                  <div class="bg-orange-50 border border-orange-100 rounded-xl p-3 text-center">
                    <span class="text-2xl font-bold text-orange-600">{{ crmStats.totalAppointments }}</span>
                    <div class="text-xs text-orange-500 mt-1">📅 Lịch hẹn</div>
                  </div>
                  <div class="bg-gray-50 border border-gray-200 rounded-xl p-3 text-center">
                    <span class="text-2xl font-bold text-gray-600">{{ crmStats.totalNotes }}</span>
                    <div class="text-xs text-gray-500 mt-1">📝 Ghi chú</div>
                  </div>
                </div>

                <!-- Toolbar -->
                <div class="flex items-center gap-3 mb-4 flex-wrap">
                  <el-dropdown trigger="click" @command="openActivityDialog">
                    <el-button type="primary">
                      + Tạo hoạt động <el-icon class="ml-1"><ArrowDown /></el-icon>
                    </el-button>
                    <template #dropdown>
                      <el-dropdown-menu>
                        <el-dropdown-item command="TASK">📋 Tác vụ</el-dropdown-item>
                        <el-dropdown-item command="CALL">📞 Cuộc gọi</el-dropdown-item>
                        <el-dropdown-item command="APPOINTMENT">📅 Lịch hẹn</el-dropdown-item>
                      </el-dropdown-menu>
                    </template>
                  </el-dropdown>
                  <el-select v-model="crmFilters.type" placeholder="Loại" clearable size="default" class="!w-36" @change="fetchCrmActivities">
                    <el-option label="Tất cả" value="" />
                    <el-option label="📋 Tác vụ" value="TASK" />
                    <el-option label="📞 Cuộc gọi" value="CALL" />
                    <el-option label="📅 Lịch hẹn" value="APPOINTMENT" />
                  </el-select>
                  <el-select v-model="crmFilters.status" placeholder="Trạng thái" clearable size="default" class="!w-40" @change="fetchCrmActivities">
                    <el-option label="Tất cả" value="" />
                    <el-option label="Chờ xử lý" value="PENDING" />
                    <el-option label="Đang xử lý" value="IN_PROGRESS" />
                    <el-option label="Hoàn thành" value="COMPLETED" />
                    <el-option label="Đã hủy" value="CANCELLED" />
                  </el-select>
                </div>

                <!-- Activity Table -->
                <el-table :data="crmActivities" stripe v-loading="loadingCrm" class="mb-6">
                  <el-table-column label="Loại" width="60" align="center">
                    <template #default="{ row }">
                      <span class="text-lg">{{ getActivityIcon(row.type) }}</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="Tiêu đề" min-width="180">
                    <template #default="{ row }">
                      <div class="font-medium">{{ row.title }}</div>
                      <div v-if="row.description" class="text-xs text-gray-400 truncate mt-0.5">{{ row.description }}</div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Người tạo" width="140">
                    <template #default="{ row }">
                      <div class="flex items-center gap-2">
                        <div class="w-6 h-6 rounded-full bg-blue-500 text-white text-xs flex items-center justify-center shrink-0">
                          {{ (row.createdBy?.fullName || row.createdBy?.username || '?').charAt(0).toUpperCase() }}
                        </div>
                        <span class="text-sm truncate">{{ row.createdBy?.fullName || row.createdBy?.username || '—' }}</span>
                      </div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Giao cho" width="140">
                    <template #default="{ row }">
                      <div v-if="row.assignedTo" class="flex items-center gap-2">
                        <div class="w-6 h-6 rounded-full bg-green-500 text-white text-xs flex items-center justify-center shrink-0">
                          {{ (row.assignedTo?.fullName || row.assignedTo?.username || '?').charAt(0).toUpperCase() }}
                        </div>
                        <span class="text-sm truncate">{{ row.assignedTo?.fullName || row.assignedTo?.username }}</span>
                      </div>
                      <span v-else class="text-gray-400 text-sm">—</span>
                    </template>
                  </el-table-column>
                  <el-table-column label="Ưu tiên" width="100" align="center">
                    <template #default="{ row }">
                      <el-tag :type="getPriorityType(row.priority)" size="small" effect="light">{{ getPriorityLabel(row.priority) }}</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="Trạng thái" width="120" align="center">
                    <template #default="{ row }">
                      <el-tag :type="getCrmStatusType(row.status)" size="small">{{ getCrmStatusLabel(row.status) }}</el-tag>
                    </template>
                  </el-table-column>
                  <el-table-column label="Thời gian" width="130" align="center">
                    <template #default="{ row }">
                      <div class="text-sm">{{ formatDateTime(row.scheduledAt || row.dueDate) }}</div>
                    </template>
                  </el-table-column>
                  <el-table-column label="Thao tác" width="160" align="center" fixed="right">
                    <template #default="{ row }">
                      <el-button v-if="row.status !== 'COMPLETED' && row.status !== 'CANCELLED'" size="small" type="success" plain @click="completeActivity(row)">✓</el-button>
                      <el-button size="small" type="primary" plain @click="editActivity(row)">Sửa</el-button>
                      <el-button size="small" type="danger" plain @click="deleteActivity(row)">Xóa</el-button>
                    </template>
                  </el-table-column>
                </el-table>
                <div v-if="!loadingCrm && crmActivities.length === 0" class="text-center py-6 text-gray-400">
                  Chưa có hoạt động chăm sóc nào.
                </div>

                <!-- Notes Section -->
                <div class="border-t border-gray-100 pt-5 mt-2">
                  <div class="flex items-center justify-between mb-4">
                    <h4 class="text-base font-semibold text-gray-700 m-0">📝 Ghi chú nội bộ</h4>
                    <el-button size="small" type="primary" plain @click="openNoteDialog()">+ Thêm ghi chú</el-button>
                  </div>
                  <div v-if="crmNotes.length === 0" class="text-center py-4 text-gray-400 text-sm">
                    Chưa có ghi chú nào.
                  </div>
                  <div v-for="note in crmNotes" :key="note.id" class="crm-note-card mb-3 p-3 rounded-xl border transition-all hover:shadow-sm" :class="note.isPinned ? 'border-amber-200 bg-amber-50/50' : 'border-gray-100 bg-white'">
                    <div class="flex items-start justify-between gap-3">
                      <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2 mb-1">
                          <span v-if="note.isPinned" class="text-amber-500">📌</span>
                          <span class="text-xs font-medium text-gray-500">
                            {{ note.createdBy?.fullName || note.createdBy?.username || 'Admin' }}
                          </span>
                          <span class="text-xs text-gray-400">• {{ formatDateTime(note.createdAt) }}</span>
                        </div>
                        <div class="text-sm text-gray-700 whitespace-pre-wrap">{{ note.content }}</div>
                      </div>
                      <div class="flex items-center gap-1 shrink-0">
                        <el-button size="small" text :type="note.isPinned ? 'warning' : 'default'" @click="togglePinNote(note)">{{ note.isPinned ? '📌' : '📍' }}</el-button>
                        <el-button size="small" text type="primary" @click="openNoteDialog(note)">✏️</el-button>
                        <el-button size="small" text type="danger" @click="deleteNote(note)">🗑️</el-button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </el-tab-pane>

          </el-tabs>
        </el-card>
      </div>

    </div>
  </div>

<!-- Activity Dialog -->
<el-dialog v-model="activityDialogVisible" :title="editingActivity ? 'Sửa hoạt động' : `Tạo ${getActivityTypeLabel(activityForm.type)}`" width="560px" destroy-on-close>
  <el-form :model="activityForm" label-width="110px" class="mt-2">
    <el-form-item label="Loại">
      <el-select v-model="activityForm.type" class="w-full">
        <el-option label="📋 Tác vụ" value="TASK" />
        <el-option label="📞 Cuộc gọi" value="CALL" />
        <el-option label="📅 Lịch hẹn" value="APPOINTMENT" />
      </el-select>
    </el-form-item>
    <el-form-item label="Tiêu đề" required>
      <el-input v-model="activityForm.title" placeholder="Nhập tiêu đề hoạt động" />
    </el-form-item>
    <el-form-item label="Mô tả">
      <el-input v-model="activityForm.description" type="textarea" :rows="3" placeholder="Mô tả chi tiết..." />
    </el-form-item>
    <el-form-item label="Ưu tiên">
      <el-select v-model="activityForm.priority" class="w-full">
        <el-option label="Thấp" value="LOW" />
        <el-option label="Trung bình" value="MEDIUM" />
        <el-option label="Cao" value="HIGH" />
        <el-option label="Gấp" value="URGENT" />
      </el-select>
    </el-form-item>
    <el-form-item v-if="editingActivity" label="Trạng thái">
      <el-select v-model="activityForm.status" class="w-full">
        <el-option label="Chờ xử lý" value="PENDING" />
        <el-option label="Đang xử lý" value="IN_PROGRESS" />
        <el-option label="Hoàn thành" value="COMPLETED" />
        <el-option label="Đã hủy" value="CANCELLED" />
      </el-select>
    </el-form-item>
    <el-form-item v-if="isAdminUser" label="Giao cho">
      <el-select v-model="activityForm.assignedToId" class="w-full" clearable placeholder="Chọn nhân viên" filterable>
        <el-option v-for="s in staffList" :key="s.id" :label="s.fullName || s.username" :value="s.id" />
      </el-select>
    </el-form-item>
    <el-form-item v-if="activityForm.type === 'APPOINTMENT' || activityForm.type === 'CALL'" label="Thời gian hẹn">
      <el-date-picker v-model="activityForm.scheduledAt" type="datetime" placeholder="Chọn ngày giờ" class="!w-full" format="DD/MM/YYYY HH:mm" value-format="YYYY-MM-DDTHH:mm:ss" />
    </el-form-item>
    <el-form-item v-if="activityForm.type === 'TASK'" label="Deadline">
      <el-date-picker v-model="activityForm.dueDate" type="datetime" placeholder="Chọn hạn chót" class="!w-full" format="DD/MM/YYYY HH:mm" value-format="YYYY-MM-DDTHH:mm:ss" />
    </el-form-item>
    <el-form-item v-if="editingActivity" label="Kết quả">
      <el-input v-model="activityForm.outcome" type="textarea" :rows="2" placeholder="Ghi kết quả..." />
    </el-form-item>
  </el-form>
  <template #footer>
    <el-button @click="activityDialogVisible = false">Hủy</el-button>
    <el-button type="primary" @click="saveActivity">{{ editingActivity ? 'Cập nhật' : 'Tạo mới' }}</el-button>
  </template>
</el-dialog>

<!-- Note Dialog -->
<el-dialog v-model="noteDialogVisible" :title="editingNote ? 'Sửa ghi chú' : 'Thêm ghi chú nội bộ'" width="500px" destroy-on-close>
  <el-form :model="noteForm" label-width="100px" class="mt-2">
    <el-form-item label="Nội dung" required>
      <el-input v-model="noteForm.content" type="textarea" :rows="5" placeholder="Nhập ghi chú nội bộ..." />
    </el-form-item>
    <el-form-item label="Ghim">
      <el-switch v-model="noteForm.isPinned" />
    </el-form-item>
  </el-form>
  <template #footer>
    <el-button @click="noteDialogVisible = false">Hủy</el-button>
    <el-button type="primary" @click="saveNote">{{ editingNote ? 'Cập nhật' : 'Thêm' }}</el-button>
  </template>
</el-dialog>

</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute } from 'vue-router';
import { adminEndUserApi, ntripUserApi, paymentApi, crmApi, adminUserApi } from '../../services/api';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Message, Phone, Calendar, Checked, RefreshRight, ArrowDown } from '@element-plus/icons-vue';
import { useAuthStore } from '../../store/auth';

const authStore = useAuthStore();
const isAdminUser = computed(() => authStore.isSuperUser || authStore.isAdmin);

const route = useRoute();
const userId = route.params.id as string;

const activeTab = ref('ntrip');
const loading = ref(true);
const loadingNtrip = ref(false);
const user = ref<any>(null);
const ntripAccounts = ref<any[]>([]);
const syncing = ref<Record<string, boolean>>({});

// ── CRM State ──
const loadingCrm = ref(false);
const crmActivities = ref<any[]>([]);
const crmNotes = ref<any[]>([]);
const crmStats = ref({ pendingTasks: 0, totalCalls: 0, totalAppointments: 0, totalNotes: 0 });
const crmFilters = ref({ type: '', status: '' });
const staffList = ref<any[]>([]);

// Activity dialog
const activityDialogVisible = ref(false);
const editingActivity = ref<any>(null);
const activityForm = ref({
  type: 'TASK',
  title: '',
  description: '',
  priority: 'MEDIUM',
  status: 'PENDING',
  scheduledAt: '',
  dueDate: '',
  assignedToId: '',
  outcome: '',
});

// Note dialog
const noteDialogVisible = ref(false);
const editingNote = ref<any>(null);
const noteForm = ref({ content: '', isPinned: false });

const fetchUserDetail = async () => {
  loading.value = true;
  try {
    const res = await adminEndUserApi.getDetail(userId);
    user.value = res.data;
    
    if (user.value.mappedNtripNames && user.value.mappedNtripNames.length > 0) {
      await fetchNtripAccounts(user.value.mappedNtripNames);
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Không thể tải thông tin khách hàng');
  } finally {
    loading.value = false;
  }
};

const fetchNtripAccounts = async (names: string[]) => {
  loadingNtrip.value = true;
  try {
    // Ideally backend has an API to fetch multiple by names, but since we list all, we can filter
    const res = await ntripUserApi.list({ page: 1, size: 9999 });
    const allAccounts = res.data?.records || res.data || [];
    ntripAccounts.value = allAccounts.filter((acc: any) => names.includes(acc.name));
  } catch (error) {
    console.error('Failed to fetch Ntrip accounts', error);
  } finally {
    loadingNtrip.value = false;
  }
};

const totalSpent = computed(() => {
  if (!user.value?.orders) return 0;
  return user.value.orders
    .filter((o: any) => o.status === 'PAID')
    .reduce((sum: number, o: any) => sum + Number(o.amount || 0), 0);
});

const handleToggleStatus = async () => {
  if (!user.value) return;
  const newStatus = user.value.status === 'ACTIVE' ? 'BLOCKED' : 'ACTIVE';
  const actionText = newStatus === 'ACTIVE' ? 'mở khóa' : 'khóa';
  
  try {
    await ElMessageBox.confirm(`Bạn có chắc chắn muốn ${actionText} tài khoản này?`, 'Xác nhận');
    await adminEndUserApi.updateStatus(user.value.id, newStatus);
    user.value.status = newStatus;
    ElMessage.success(`Đã ${actionText} tài khoản thành công`);
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error('Có lỗi xảy ra');
  }
};

const handleSyncPayment = async (order: any) => {
  if (!order.payosOrderCode) {
    ElMessage.warning('Đơn hàng này không có mã giao dịch PayOS');
    return;
  }
  
  syncing.value[order.id] = true;
  try {
    const res = await paymentApi.syncStatus(order.payosOrderCode);
    if (res.data?.isPaid) {
      ElMessage.success('Tuyệt vời! Giao dịch đã được thanh toán trên PayOS. Trạng thái đã được đồng bộ.');
      // Refresh timeline and accounts
      await fetchUserDetail();
    } else {
      ElMessage.info('Giao dịch chưa được thanh toán (hoặc đã bị hủy) trên PayOS.');
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Lỗi khi kiểm tra trạng thái thanh toán');
  } finally {
    syncing.value[order.id] = false;
  }
};

const formatDate = (dateString: string | number) => {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleDateString('vi-VN');
};

const formatPrice = (amount: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
};

const isExpired = (ts: number | string) => {
  if (!ts) return false;
  return new Date(ts).getTime() < Date.now();
};

const daysLeft = (ts: number | string) => {
  if (!ts) return 0;
  const diff = new Date(ts).getTime() - Date.now();
  return Math.ceil(diff / (1000 * 3600 * 24));
};

const formatStatus = (status: string) => {
  const vmap: Record<string, string> = {
    OPEN: 'Mở', IN_PROGRESS: 'Đang xử lý', RESOLVED: 'Đã giải quyết', CLOSED: 'Đóng'
  };
  return vmap[status] || status;
};

const getStatusType = (status: string) => {
  const tmap: Record<string, string> = {
    OPEN: 'danger', IN_PROGRESS: 'warning', RESOLVED: 'success', CLOSED: 'info'
  };
  return tmap[status] || 'info';
};

// ── CRM Functions ──
const fetchCrmActivities = async () => {
  loadingCrm.value = true;
  try {
    const res = await crmApi.listActivities({
      userId,
      type: crmFilters.value.type || undefined,
      status: crmFilters.value.status || undefined,
    });
    crmActivities.value = res.data?.items || [];
  } catch (error) {
    console.error('Failed to fetch CRM activities', error);
  } finally {
    loadingCrm.value = false;
  }
};

const fetchCrmNotes = async () => {
  try {
    const res = await crmApi.listNotes({ userId });
    crmNotes.value = res.data || [];
  } catch (error) {
    console.error('Failed to fetch CRM notes', error);
  }
};

const fetchCrmStats = async () => {
  try {
    const res = await crmApi.getStats(userId);
    crmStats.value = res.data || { pendingTasks: 0, totalCalls: 0, totalAppointments: 0, totalNotes: 0 };
  } catch (error) {
    console.error('Failed to fetch CRM stats', error);
  }
};

const fetchStaffList = async () => {
  try {
    const res = await adminUserApi.list({ limit: 200 });
    const allUsers = res.data?.data || [];
    staffList.value = allUsers.filter((u: any) => {
      const role = u.role?.name || u.roleName || '';
      return role !== 'END_USER' && role !== 'end_user';
    });
  } catch (error) {
    console.error('Failed to fetch staff list', error);
  }
};

const loadCrmData = () => {
  fetchCrmActivities();
  fetchCrmNotes();
  fetchCrmStats();
};

const openActivityDialog = (type: string) => {
  editingActivity.value = null;
  activityForm.value = {
    type,
    title: '',
    description: '',
    priority: 'MEDIUM',
    status: 'PENDING',
    scheduledAt: '',
    dueDate: '',
    assignedToId: '',
    outcome: '',
  };
  if (staffList.value.length === 0) fetchStaffList();
  activityDialogVisible.value = true;
};

const editActivity = (row: any) => {
  editingActivity.value = row;
  activityForm.value = {
    type: row.type,
    title: row.title,
    description: row.description || '',
    priority: row.priority,
    status: row.status,
    scheduledAt: row.scheduledAt || '',
    dueDate: row.dueDate || '',
    assignedToId: row.assignedToId || '',
    outcome: row.outcome || '',
  };
  if (staffList.value.length === 0) fetchStaffList();
  activityDialogVisible.value = true;
};

const saveActivity = async () => {
  if (!activityForm.value.title) {
    ElMessage.warning('Vui lòng nhập tiêu đề');
    return;
  }
  try {
    const form = activityForm.value;

    if (editingActivity.value) {
      // Update: only send fields from UpdateCrmActivityDto
      const updatePayload: any = {
        title: form.title,
        status: form.status,
        priority: form.priority,
      };
      if (form.description) updatePayload.description = form.description;
      if (form.type) updatePayload.type = form.type;
      if (form.scheduledAt) updatePayload.scheduledAt = form.scheduledAt;
      if (form.dueDate) updatePayload.dueDate = form.dueDate;
      if (form.assignedToId) updatePayload.assignedToId = form.assignedToId;
      if (form.outcome) updatePayload.outcome = form.outcome;

      await crmApi.updateActivity(editingActivity.value.id, updatePayload);
      ElMessage.success('Đã cập nhật hoạt động');
    } else {
      // Create: match CreateCrmActivityDto
      const createPayload: any = {
        type: form.type,
        title: form.title,
        userId,
      };
      if (form.description) createPayload.description = form.description;
      if (form.priority) createPayload.priority = form.priority;
      if (form.scheduledAt) createPayload.scheduledAt = form.scheduledAt;
      if (form.dueDate) createPayload.dueDate = form.dueDate;
      if (form.assignedToId) createPayload.assignedToId = form.assignedToId;

      await crmApi.createActivity(createPayload);
      ElMessage.success('Đã tạo hoạt động mới');
    }
    activityDialogVisible.value = false;
    loadCrmData();
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Lỗi khi lưu hoạt động');
  }
};

const completeActivity = async (row: any) => {
  try {
    await crmApi.updateActivity(row.id, { status: 'COMPLETED' });
    ElMessage.success('Đã đánh dấu hoàn thành');
    loadCrmData();
  } catch (error: any) {
    ElMessage.error('Lỗi khi cập nhật');
  }
};

const deleteActivity = async (row: any) => {
  try {
    await ElMessageBox.confirm('Bạn có chắc chắn muốn xóa hoạt động này?', 'Xác nhận');
    await crmApi.deleteActivity(row.id);
    ElMessage.success('Đã xóa');
    loadCrmData();
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error('Lỗi khi xóa');
  }
};

const openNoteDialog = (note?: any) => {
  editingNote.value = note || null;
  noteForm.value = {
    content: note?.content || '',
    isPinned: note?.isPinned || false,
  };
  noteDialogVisible.value = true;
};

const saveNote = async () => {
  if (!noteForm.value.content.trim()) {
    ElMessage.warning('Vui lòng nhập nội dung ghi chú');
    return;
  }
  try {
    if (editingNote.value) {
      await crmApi.updateNote(editingNote.value.id, noteForm.value);
      ElMessage.success('Đã cập nhật ghi chú');
    } else {
      await crmApi.createNote({ userId, ...noteForm.value });
      ElMessage.success('Đã thêm ghi chú');
    }
    noteDialogVisible.value = false;
    loadCrmData();
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Lỗi khi lưu ghi chú');
  }
};

const togglePinNote = async (note: any) => {
  try {
    await crmApi.updateNote(note.id, { isPinned: !note.isPinned });
    loadCrmData();
  } catch (error) {
    ElMessage.error('Lỗi khi ghim/bỏ ghim');
  }
};

const deleteNote = async (note: any) => {
  try {
    await ElMessageBox.confirm('Xóa ghi chú này?', 'Xác nhận');
    await crmApi.deleteNote(note.id);
    ElMessage.success('Đã xóa ghi chú');
    loadCrmData();
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error('Lỗi khi xóa');
  }
};

const getActivityIcon = (type: string) => {
  const icons: Record<string, string> = { TASK: '📋', CALL: '📞', APPOINTMENT: '📅' };
  return icons[type] || '📋';
};

const getActivityTypeLabel = (type: string) => {
  const labels: Record<string, string> = { TASK: 'Tác vụ', CALL: 'Cuộc gọi', APPOINTMENT: 'Lịch hẹn' };
  return labels[type] || type;
};

const getPriorityType = (p: string) => {
  const m: Record<string, string> = { LOW: 'info', MEDIUM: '', HIGH: 'warning', URGENT: 'danger' };
  return m[p] || 'info';
};

const getPriorityLabel = (p: string) => {
  const m: Record<string, string> = { LOW: 'Thấp', MEDIUM: 'TB', HIGH: 'Cao', URGENT: 'Gấp' };
  return m[p] || p;
};

const getCrmStatusType = (s: string) => {
  const m: Record<string, string> = { PENDING: 'warning', IN_PROGRESS: 'primary', COMPLETED: 'success', CANCELLED: 'info' };
  return m[s] || 'info';
};

const getCrmStatusLabel = (s: string) => {
  const m: Record<string, string> = { PENDING: 'Chờ xử lý', IN_PROGRESS: 'Đang xử lý', COMPLETED: 'Hoàn thành', CANCELLED: 'Đã hủy' };
  return m[s] || s;
};

const formatDateTime = (dt: string | number) => {
  if (!dt) return '—';
  return new Date(dt).toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
};

// Load CRM data when tab switches to 'crm'
watch(activeTab, (val) => {
  if (val === 'crm' && crmActivities.value.length === 0) {
    loadCrmData();
  }
});

onMounted(() => {
  fetchUserDetail();
});
</script>


<style scoped>
.dashboard-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 500;
  color: #6b7280;
  padding: 0 24px;
}
.dashboard-tabs :deep(.el-tabs__item.is-active) {
  color: #3b82f6;
  font-weight: 600;
}
.dashboard-tabs :deep(.el-tabs__active-bar) {
  height: 3px;
  background-color: #3b82f6;
  border-radius: 3px 3px 0 0;
}
.dashboard-tabs :deep(.el-tabs__nav-wrap::after) {
  background-color: #f3f4f6;
}
.crm-note-card {
  transition: all 0.2s ease;
}
.crm-note-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}
</style>
