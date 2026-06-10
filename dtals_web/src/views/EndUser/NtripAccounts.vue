<template>
  <div>
    <div class="flex justify-between items-center mb-8">
      <div>
        <!--<h2 class="text-2xl font-bold text-gray-800">Tài khoản NTRIP của tôi</h2>-->
        <p class="text-gray-500">Quản lý và gia hạn tài khoản kết nối trạm  DTALS</p>
      </div>
      <el-button type="primary" size="large" @click="openCreateDialog">
        + Tạo tài khoản mới
      </el-button>
    </div>

    <!-- Khuyến cáo KYC chưa duyệt -->
    <el-alert v-if="ekycStatus === 'NEEDS_REVIEW'" type="warning" show-icon class="mb-6"
      title="Hồ sơ KYC đang chờ duyệt" 
      description="Bạn có thể tạo trước thông tin tài khoản NTRIP, nhưng cần chờ quản trị viên duyệt KYC và thanh toán đơn hàng trước khi tài khoản được kích hoạt." />
    
    <el-alert v-if="ekycStatus === 'REJECTED' || ekycStatus === 'NONE'" type="error" show-icon class="mb-6"
      title="Chưa xác thực danh tính" 
      description="Bạn cần hoàn thành bước Xác thực eKYC trước khi tạo tài khoản NTRIP." />

    <!-- Danh sách NTRIP Accounts -->
    <el-card shadow="hover" class="!border-none !rounded-xl min-h-[400px]">
      <div v-if="loading" class="flex justify-center items-center h-[300px]">
        <el-icon class="is-loading text-blue-500 text-3xl"><Loading /></el-icon>
      </div>
      
      <div v-else-if="accounts.length === 0" class="flex flex-col items-center justify-center h-[300px] text-gray-400">
        <el-icon class="text-6xl mb-4 text-gray-200"><Box /></el-icon>
        <p class="mb-4">Bạn chưa có tài khoản NTRIP nào.</p>
        <el-button type="primary" @click="openCreateDialog" :disabled="!canCreate">Tạo tài khoản đầu tiên</el-button>
      </div>

      <el-table v-else :data="allAccounts" border stripe tooltip-effect="dark">
        <el-table-column prop="ntripId" label="Tài khoản NTRIP / Tên đăng nhập" min-width="200">
          <template #default="{ row }">
            <div class="font-medium text-blue-700">{{ row.name || row.ntripAccountName }}</div>
          </template>
        </el-table-column>
        <el-table-column label="Gói cước" min-width="150">
          <template #default="{ row }">
            <span v-if="row._packageName" class="text-sm">{{ row._packageName }}</span>
            <span v-else class="text-gray-400">-</span>
          </template>
        </el-table-column>
        <el-table-column label="Ngày hết hạn" min-width="150" align="center">
          <template #default="{ row }">
            <span v-if="row.endTime">{{ formatDate(row.endTime) }}</span>
            <span v-else class="text-gray-400">-</span>
          </template>
        </el-table-column>
        <el-table-column label="Trạng thái" min-width="160" align="center">
          <template #default="{ row }">
            <el-tag v-if="row._source === 'order' && row._orderStatus === 'PENDING'" type="warning">Chờ thanh toán</el-tag>
            <el-tag v-else-if="row._source === 'order' && row._orderStatus === 'PAID'" type="info">Chờ kích hoạt</el-tag>
            <el-tag v-else-if="row.enabled === 1" type="success">Đang hoạt động</el-tag>
            <el-tag v-else type="danger">Chưa kích hoạt</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="Thao tác" width="200" align="center">
          <template #default="{ row }">
            <el-button v-if="row._source === 'order' && row._orderStatus === 'PENDING'" size="small" type="warning" plain @click="$router.push('/user/orders')">Thanh toán</el-button>
            <el-button v-else-if="row._source !== 'order'" size="small" type="primary" plain @click="renewAccount(row)">Gia hạn</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Modal Tạo tài khoản mới -->
    <el-dialog v-model="showCreateDialog" title="Tạo tài khoản NTRIP mới" width="500px">
      <div v-if="!canCreate" class="text-center py-4">
        <el-icon class="text-red-500 text-4xl mb-2"><Warning /></el-icon>
        <p class="text-gray-600">Vui lòng hoàn thành Xác nhận eKYC trước khi tạo tài khoản.</p>
        <el-button class="mt-4" type="primary" @click="$router.push('/user/ekyc')">Đi đến Xác thực</el-button>
      </div>
      
      <el-form v-else :model="form" :rules="rules" ref="formRef" label-position="top">
        <el-form-item label="Tên tài khoản (Tên đăng nhập NTRIP)" prop="name">
          <el-input v-model="form.name" placeholder="Ví dụ: RtkCORS_01" />
          <div class="text-xs text-gray-400 mt-1">Tên này dùng để đăng nhập trên thiết bị Rover của bạn.</div>
        </el-form-item>
        
        <el-form-item label="Mật khẩu NTRIP" prop="password">
          <el-input v-model="form.password" type="password" show-password placeholder="Mật khẩu kết nối" />
        </el-form-item>
        
        <el-form-item label="Chọn gói cước" prop="packageId">
          <div v-if="packagesLoading" class="text-sm text-gray-500"><el-icon class="is-loading"><Loading/></el-icon> Đang tải bảng giá...</div>
          <el-select v-else v-model="form.packageId" placeholder="Chọn gói thuê bao cho tài khoản" class="w-full">
            <el-option
              v-for="pkg in activePackages"
              :key="pkg.id"
              :label="`${pkg.name} - ${formatPrice(pkg.price)}`"
              :value="pkg.id"
            >
              <div class="flex justify-between items-center w-full pr-4">
                <span>{{ pkg.name }}</span>
                <span class="font-bold text-blue-600">{{ formatPrice(pkg.price) }}</span>
              </div>
            </el-option>
          </el-select>
        </el-form-item>

        <div class="grid grid-cols-2 gap-4">
          <el-form-item label="Số lượng" prop="quantity">
            <el-input-number v-model="form.quantity" :min="1" :max="24" class="w-full" />
          </el-form-item>
          <el-form-item label="Ngày bắt đầu" prop="startTime">
            <el-date-picker
              v-model="form.startTime"
              type="date"
              placeholder="Chọn ngày"
              class="w-full"
              :disabled-date="(date: Date) => date < new Date(new Date().setHours(0,0,0,0))"
              value-format="x"
            />
          </el-form-item>
        </div>

        <!-- Order Summary -->
        <div v-if="form.packageId" class="bg-gray-50 p-4 rounded-lg border border-gray-200 text-sm space-y-2">
          <h4 class="font-semibold text-gray-800 mb-2">Tóm tắt đơn hàng</h4>
          <div class="flex justify-between"><span class="text-gray-500">Gói cước:</span><span>{{ selectedPackageName }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Số lượng:</span><span>x{{ form.quantity }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Thời gian sử dụng:</span><span class="font-medium">{{ totalDurationText }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Ngày bắt đầu:</span><span>{{ formattedStartDate }}</span></div>
          <div class="flex justify-between"><span class="text-gray-500">Ngày kết thúc:</span><span class="font-medium text-blue-600">{{ formattedEndDate }}</span></div>
          <el-divider class="!my-2" />
          <div class="flex justify-between text-base"><span class="font-bold">Tổng tiền:</span><span class="font-bold text-red-500">{{ formatPrice(totalAmount) }}</span></div>
        </div>
      </el-form>

      <template #footer>
        <span v-if="canCreate" class="dialog-footer">
          <el-button @click="showCreateDialog = false">Hủy</el-button>
          <el-button type="primary" :loading="submitting" @click="submitCreateAccount">
            Tạo tài khoản
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import type { FormInstance, FormRules } from 'element-plus';
import { ntripUserApi, ekycApi, packageApi, orderApi } from '../../services/api';
import { Loading, Box, Warning } from '@element-plus/icons-vue';

const router = useRouter();
const accounts = ref<any[]>([]);
const allAccounts = computed(() => accounts.value);
const loading = ref(true);
const ekycStatus = ref('NONE');
const showCreateDialog = ref(false);
const submitting = ref(false);

const activePackages = ref<any[]>([]);
const packagesLoading = ref(false);

const formRef = ref<FormInstance>();
const form = ref({
  name: '',
  password: '',
  packageId: null as number | null,
  quantity: 1,
  startTime: null as number | null,
});

const rules = ref<FormRules>({
  name: [
    { required: true, message: 'Vui lòng nhập tên tài khoản', trigger: 'blur' },
    { min: 4, message: 'Tên phải chứa ít nhất 4 ký tự', trigger: 'blur' }
  ],
  password: [
    { required: true, message: 'Vui lòng nhập mật khẩu', trigger: 'blur' },
    { min: 6, message: 'Mật khẩu phải chứa ít nhất 6 ký tự', trigger: 'blur' }
  ],
  packageId: [
    { required: true, message: 'Vui lòng chọn gói cước', trigger: 'change' }
  ]
});

// User needs approved KYC to actually create NTRIP accounts, but we might allow NEEDS_REVIEW visually
const canCreate = computed(() => ekycStatus.value === 'APPROVED' || ekycStatus.value === 'VERIFIED' || ekycStatus.value === 'NEEDS_REVIEW');

onMounted(async () => {
  await fetchKycStatus();
  await loadAccounts();
  await loadPackages();
});

const fetchKycStatus = async () => {
  try {
    const res = await ekycApi.getStatus();
    ekycStatus.value = res.data.kycStatus || res.data.status || 'NONE';
  } catch (err: any) {
    if (err.response?.status === 404) ekycStatus.value = 'NONE';
  }
};

const loadAccounts = async () => {
  loading.value = true;
  try {
    // 1. Load CGBAS accounts
    try {
      const res = await ntripUserApi.list({ page: 1, size: 50 });
      accounts.value = (res.data.items || res.data || []).map((a: any) => ({ ...a, _source: 'cgbas' }));
    } catch {
      accounts.value = [];
    }

    // 2. Load orders and merge pending/paid ones
    try {
      const orderRes = await orderApi.list();
      const orders = orderRes.data || [];
      orders.forEach((order: any) => {
        if (['PENDING', 'PAID'].includes(order.status)) {
          const exists = accounts.value.find((a: any) => a.name === order.ntripAccountName);
          if (!exists) {
            accounts.value.push({
              name: order.ntripAccountName,
              _source: 'order',
              _orderStatus: order.status,
              _packageName: order.packageName,
              _orderId: order.id,
              enabled: 0,
              endTime: null,
            });
          }
        }
      });
    } catch {
      // Orders API may not be available
    }
  } finally {
    loading.value = false;
  }
};

const loadPackages = async () => {
  packagesLoading.value = true;
  try {
    const res = await packageApi.listActive();
    activePackages.value = res.data || [];
  } catch (error) {
    // Fallback Mock Data if API not implemented yet
    activePackages.value = [
      { id: 1, name: 'Gói Cơ bản (1 Tháng)', price: 500000 },
      { id: 2, name: 'Gói Tiêu chuẩn (6 Tháng)', price: 2500000 },
      { id: 3, name: 'Gói VIP (12 Tháng)', price: 4500000 }
    ];
  } finally {
    packagesLoading.value = false;
  }
};

const openCreateDialog = () => {
  form.value = { name: '', password: '', packageId: null, quantity: 1, startTime: Date.now() };
  if (activePackages.value.length === 1) {
    form.value.packageId = activePackages.value[0].id;
  }
  showCreateDialog.value = true;
};

const selectedPackage = computed(() => activePackages.value.find(p => p.id === form.value.packageId));
const selectedPackageName = computed(() => selectedPackage.value?.name || '-');

const totalAmount = computed(() => {
  if (!selectedPackage.value) return 0;
  return selectedPackage.value.price * (form.value.quantity || 1);
});

const unitLabel = (unit: string) => {
  const map: Record<string, string> = { day: 'ngày', month: 'tháng', year: 'năm' };
  return map[unit] || 'tháng';
};

const totalDurationText = computed(() => {
  if (!selectedPackage.value) return '-';
  const unitDuration = selectedPackage.value.duration || 1;
  const total = unitDuration * (form.value.quantity || 1);
  const unit = (selectedPackage.value as any).durationUnit || 'month';
  return `${total} ${unitLabel(unit)}`;
});

const computedEndDate = computed(() => {
  if (!selectedPackage.value) return null;
  const unitDuration = selectedPackage.value.duration || 1;
  const total = unitDuration * (form.value.quantity || 1);
  const unit = (selectedPackage.value as any).durationUnit || 'month';
  const start = form.value.startTime ? new Date(form.value.startTime) : new Date();
  const end = new Date(start);
  if (unit === 'day') {
    end.setDate(end.getDate() + total);
  } else if (unit === 'year') {
    end.setFullYear(end.getFullYear() + total);
  } else {
    end.setMonth(end.getMonth() + total);
  }
  return end;
});

const formattedStartDate = computed(() => {
  const d = form.value.startTime ? new Date(form.value.startTime) : new Date();
  return d.toLocaleDateString('vi-VN');
});

const formattedEndDate = computed(() => {
  return computedEndDate.value ? computedEndDate.value.toLocaleDateString('vi-VN') : '-';
});

const submitCreateAccount = async () => {
  if (!formRef.value) return;
  await formRef.value.validate(async (valid) => {
    if (valid) {
      if (ekycStatus.value !== 'APPROVED' && ekycStatus.value !== 'VERIFIED') {
        ElMessage.warning('Tài khoản sẽ được lưu nháp do Hồ sơ KYC chưa được phê duyệt hoàn toàn.');
      }
      submitting.value = true;
      try {
        // 1. Gửi request tạo thông tin NTRIP lên backend. 
        // Backend sẽ tự động tạo Order trạng thái PENDING & liên kết với packageId
        await orderApi.create({
          ntripAccountName: form.value.name,
          ntripPassword: form.value.password,
          packageId: form.value.packageId!,
          quantity: form.value.quantity || 1,
          startTime: form.value.startTime || undefined,
        });
        
        ElMessage.success('Tạo yêu cầu thành công! Vui lòng thanh toán đơn hàng.');
        showCreateDialog.value = false;
        
        // Chuyển hướng tới trang thanh toán để gom đơn
        router.push('/user/orders');
      } catch (error: any) {
        ElMessage.error(error.response?.data?.message || 'Có lỗi khi tạo tài khoản.');
      } finally {
        submitting.value = false;
      }
    }
  });
};

const renewAccount = (row: any) => {
  form.value.name = row.name;
  form.value.password = '';
  form.value.packageId = null;
  form.value.quantity = 1;
  form.value.startTime = Date.now();
  showCreateDialog.value = true;
};

const formatPrice = (price: number) => {
  if (price === 0) return 'Miễn phí';
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
};

const formatDate = (ts: number | string) => {
  const date = new Date(ts);
  return date.toLocaleDateString('vi-VN');
};
</script>
