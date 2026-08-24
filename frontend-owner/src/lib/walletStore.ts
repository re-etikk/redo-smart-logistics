export interface BankAccount {
  id: string;
  bankName: string;
  accountNumber: string;
  ifsc: string;
  accountHolder: string;
  accountType: "Current" | "Savings";
  upiId?: string;
  isPrimary: boolean;
  verified: boolean;
}

export interface WalletTransaction {
  id: string;
  txId: string;
  utrNumber: string;
  type: "Payout" | "Trip Earning" | "Advance" | "FASTag Deduction";
  amount: number;
  direction: "credit" | "debit";
  description: string;
  truckName?: string;
  regNo?: string;
  tripId?: string;
  date: string;
  timestamp: number;
  status: "Completed" | "Processing" | "Failed";
  mode: "Bank Transfer (NEFT/IMPS)" | "Instant UPI" | "Auto FASTag" | "Freight Escrow";
  beneficiary?: string;
}

export interface WalletState {
  balance: number;
  pendingPayouts: number;
  totalWithdrawn: number;
  bankAccounts: BankAccount[];
  transactions: WalletTransaction[];
}

// NEW ACCOUNTS START WITH ZERO BALANCE, ZERO TRANSACTIONS, ZERO BANK ACCOUNTS
const INITIAL_BANK_ACCOUNTS: BankAccount[] = [];
const INITIAL_TRANSACTIONS: WalletTransaction[] = [];

const STORAGE_KEY = "redo_owner_wallet_v3";

export function getWallet(): WalletState {
  if (typeof window === "undefined") {
    return {
      balance: 0,
      pendingPayouts: 0,
      totalWithdrawn: 0,
      bankAccounts: INITIAL_BANK_ACCOUNTS,
      transactions: INITIAL_TRANSACTIONS,
    };
  }
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      const initial: WalletState = {
        balance: 0,
        pendingPayouts: 0,
        totalWithdrawn: 0,
        bankAccounts: INITIAL_BANK_ACCOUNTS,
        transactions: INITIAL_TRANSACTIONS,
      };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(initial));
      return initial;
    }
    return JSON.parse(saved);
  } catch {
    return {
      balance: 0,
      pendingPayouts: 0,
      totalWithdrawn: 0,
      bankAccounts: INITIAL_BANK_ACCOUNTS,
      transactions: INITIAL_TRANSACTIONS,
    };
  }
}

export function saveWallet(state: WalletState): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    window.dispatchEvent(new Event("redo_wallet_updated"));
  } catch {}
}

export function requestPayout(amount: number, bankAccountId: string): { success: boolean; message: string } {
  const wallet = getWallet();
  if (amount <= 0) return { success: false, message: "Invalid withdrawal amount" };
  if (amount > wallet.balance) return { success: false, message: "Insufficient wallet balance" };

  const bank = wallet.bankAccounts.find(b => b.id === bankAccountId) || wallet.bankAccounts[0];
  if (!bank) return { success: false, message: "Please add a bank account first" };

  const utr = `UTR${Date.now().toString().slice(-10)}`;
  const now = new Date();
  const dateStr = now.toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });

  const newTxn: WalletTransaction = {
    id: `TXN-${Date.now().toString().slice(-4)}`,
    txId: `REDO-PAY-${Math.floor(10000 + Math.random() * 90000)}`,
    utrNumber: utr,
    type: "Payout",
    amount,
    direction: "debit",
    description: `Withdrawal to ${bank.bankName} (A/C ••${bank.accountNumber.slice(-4)})`,
    date: dateStr,
    timestamp: Date.now(),
    status: "Completed",
    mode: "Bank Transfer (NEFT/IMPS)",
    beneficiary: `${bank.bankName} (••${bank.accountNumber.slice(-4)})`
  };

  const updated: WalletState = {
    ...wallet,
    balance: wallet.balance - amount,
    totalWithdrawn: wallet.totalWithdrawn + amount,
    transactions: [newTxn, ...wallet.transactions],
  };

  saveWallet(updated);
  return { success: true, message: `₹${amount.toLocaleString("en-IN")} transferred successfully to ${bank.bankName}. UTR: ${utr}` };
}

export function addMoneyToWallet(amount: number): void {
  const wallet = getWallet();
  const now = new Date();
  const dateStr = now.toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });

  const newTxn: WalletTransaction = {
    id: `TXN-${Date.now().toString().slice(-4)}`,
    txId: `REDO-TOPUP-${Math.floor(10000 + Math.random() * 90000)}`,
    utrNumber: `UPI${Date.now().toString().slice(-10)}`,
    type: "Advance",
    amount,
    direction: "credit",
    description: "Instant Wallet Top-up (UPI / NetBanking)",
    date: dateStr,
    timestamp: Date.now(),
    status: "Completed",
    mode: "Instant UPI",
    beneficiary: "REDO Wallet"
  };

  const updated: WalletState = {
    ...wallet,
    balance: wallet.balance + amount,
    transactions: [newTxn, ...wallet.transactions],
  };

  saveWallet(updated);
}

export function addBankAccount(bank: Omit<BankAccount, "id" | "verified">): void {
  const wallet = getWallet();
  const newAccount: BankAccount = {
    ...bank,
    id: `BANK-${Date.now().toString().slice(-4)}`,
    verified: true,
  };
  const updated: WalletState = {
    ...wallet,
    bankAccounts: [newAccount, ...wallet.bankAccounts],
  };
  saveWallet(updated);
}

export function depositTripEarning(amount: number, description: string, tripId?: string, regNo?: string): void {
  const wallet = getWallet();
  const now = new Date();
  const dateStr = now.toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });

  const newTxn: WalletTransaction = {
    id: `TXN-${Date.now().toString().slice(-4)}`,
    txId: `REDO-EARN-${Math.floor(10000 + Math.random() * 90000)}`,
    utrNumber: `ESCROW${Date.now().toString().slice(-10)}`,
    type: "Trip Earning",
    amount,
    direction: "credit",
    description,
    tripId,
    regNo,
    date: dateStr,
    timestamp: Date.now(),
    status: "Completed",
    mode: "Freight Escrow",
    beneficiary: "REDO Fleet Balance"
  };

  const updated: WalletState = {
    ...wallet,
    balance: wallet.balance + amount,
    transactions: [newTxn, ...wallet.transactions],
  };

  saveWallet(updated);
}
