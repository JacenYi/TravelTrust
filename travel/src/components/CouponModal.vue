<template>
  <a-modal
    :visible="modelValue"
    :width="400"
    @close="handleCancel"
    :closable="false"
    :footer="false"
  >
    <template #title>
    </template>
    <div class="coupon-modal-content">
      <div class="coupon-header">
        <h3 class="coupon-name">{{ couponName }}</h3>
        <span class="coupon-status" v-if="isCouponActive">Available</span>
      </div>
      
      <span class="coupon-description">{{ couponDescription }}</span>
      
      <div class="coupon-validity">
        <span>Valid until: {{ couponExpiryDate }}</span>
      </div>
      
      <div class="qrcode-container">
        <div class="qrcode-placeholder">
          <QRCode :value="qrcodeContent" :size="200" level="M" />
        </div>
      </div>
      <div class="button-box">
        <a-button class="confirm-button" :loading="loading" shape="round" type="primary" @click="handleConfirm">Confirm Use</a-button>
        <a-button shape="round" :disabled="loading" @click="handleCancel">Cancel</a-button>
      </div>
    </div>
  </a-modal>
</template>

<script setup>
import { defineProps, defineEmits, computed, ref } from 'vue'
import QRCode from 'qrcode.vue'
import { EthereumService } from '../services/ethereum'
import { Message } from '@arco-design/web-vue'
import { useWalletStore } from '../stores/wallet'

const walletStore = useWalletStore()
const ethereumService = new EthereumService()
const loading = ref(false)

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  couponData: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel'])

const couponName = computed(() => props.couponData?.name || 'Coupon Name')
const couponDescription = computed(() => props.couponData?.description || 'Coupon Description')
const couponExpiryDate = computed(() => props.couponData?.expiryDate || '2026-10-31')
const isCouponActive = computed(() => props.couponData?.status === 'Active')

const qrcodeContent = computed(() => {
  return JSON.stringify({
    type: 'coupon',
    id: props.couponData.id || 'default',
    name: props.couponData.name,
    expiryDate: props.couponData.expiryDate
  })
})

const handleConfirm = async () => {
  if (!walletStore.ethereumConnected) {
    Message.error('Please connect your wallet first')
    return
  }

  loading.value = true
  
  try {
    await ethereumService.verifyCoupon(props.couponData.couponCode || 'default')
    props.couponData.status = 'Used'
    Message.success('Coupon used successfully')
    emit('confirm', props.couponData)
    emit('update:modelValue', false)
  } catch (error) {
    Message.error(`Coupon use failed, ${error.reason || error.message}`)
    console.error('Coupon use failed:', error)
    emit('update:modelValue', false)
  } finally {
    loading.value = false
  }
}

const handleCancel = () => {
  emit('cancel')
  emit('update:modelValue', false)
}
</script>

<style scoped>
.coupon-modal-content {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.coupon-header {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.coupon-name {
  font-size: 18px;
  font-weight: 600;
  margin: 0;
  color: #333;
}

.coupon-status {
  color: #52c41a;
  font-size: 12px;
  background-color: #f6ffed;
  padding: 2px 8px;
  border-radius: 4px;
}

.coupon-description {
  color: #666;
  margin-bottom: 16px;
  width: 100%;
  border-bottom: 1px solid #e0e0e0;
  padding: 12px;
  border-radius: 4px;
}

.coupon-validity {
  width: 100%;
  text-align: left;
  font-size: 14px;
  color: #999;
  margin-bottom: 24px;
}

.qrcode-container {
  margin: 20px 0;
  display: flex;
  justify-content: center;
}

.qrcode-placeholder {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 10px;
}

.qrcode-svg {
  border: 1px solid #e0e0e0;
}

.button-box {
  display: flex;
  justify-content: center;
  align-items: center;
}

.confirm-button {
  margin-right: 20px;
}
</style>

