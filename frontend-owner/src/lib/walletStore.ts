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

const INITIAL_BANK_ACCOUNTS: BankAccount[] = [
  {
    id: "BANK-01",
    bankName: "HDFC Bank Ltd",
    accountNumber: "50200084920192",
    ifsc: "HDFC0000128",
    accountHolder: "Ritik Chaurasia Logistics",
    accountType: "Current",
    upiId: "ritikchaurasia@okhdfcbank",
    isPrimary: true,
    verified: true,
  },
  {
    id: "BANK-02",
    bankName: "State Bank of India",
    accountNumber: "38920184910",
    ifsc: "SBIN0001124",
    accountHolder: "Ritik Chaurasia",
    accountType: "Savings",
    upiId: "9876543210@sbi",
    isPrimary: false,
    verified: true,
  }
];

const INITIAL_TRANSACTIONS: WalletTransaction[] = [
  {
    id: "TXN-101",
    txId: "REDO-PAY-98124",
    utrNumber: "UTR2026082200981",
    type: "Trip Earning",
    amount: 24500,
    direction: "credit",
    description: "Freight Payout: Delhi → Mumbai Corridor",
    truckName: "Eicher Pro 2049",
    regNo: "HR 55 AB 1234",
    tripId: "TRIP-881",
    date: "22 Aug 2026, 05:30 PM",
    timestamp: Date.now() - 86400000,
    status: "Completed",
    mode: "Freight Escrow",
    beneficiary: "HDFC Bank (••92)"
  },
  {
    id: "TXN-102",
    txId: "REDO-PAY-98123",
    utrNumber: "UTR2026082100412",
    type: "Payout",
    amount: 20000,
    direction: "debit",
    description: "Instant Bank Withdrawal to HDFC Bank",
    date: "21 Aug 2026, 11:15 AM",
    timestamp: Date.now() - 172800000,
    status: "Completed",
    mode: "Bank Transfer (NEFT/IMPS)",
    beneficiary: "HDFC Bank (••92)"
  },
  {
    id: "TXN-103",
    txId: "REDO-PAY-98122",
    utrNumber: "UTR2026081900192",
    type: "Trip Earning",
    amount: 18200,
    direction: "credit",
    description: "Freight Payout: Mumbai → Ahmedabad Corridor",
    truckName: "BharatBenz 1917R",
    regNo: "HR 55 CD 5678",
    tripId: "TRIP-882",
    date: "19 Aug 2026, 09:20 AM",
    timestamp: Date.now() - 345600000,
    status: "Completed",
    mode: "Freight Escrow",
    beneficiary: "HDFC Bank (••92)"
  },
  {
    id: "TXN-104",
    txId: "REDO-PAY-98121",
    utrNumber: "UTR2026081800984",
    type: "FASTag Deduction",
    amount: 1860,
    direction: "debit",
    description: "Automated NHAI Toll Clearance (Delhi - Jaipur Highway)",
    truckName: "Eicher Pro 2049",
    regNo: "HR 55 AB 1234",
    date: "18 Aug 2026, 02:40 PM",
    timestamp: Date.now() - 432000000,
    status: "Completed",
    mode: "Auto FASTag",
    beneficiary: "IHMCL NHAI Toll"
  }
];

const STORAGE_KEY = "redo_owner_wallet_v2";

export function getWallet(): WalletState {
  if (typeof window === "undefined") {
    return {
      balance: 24560,
      pendingPayouts: 0,
      totalWithdrawn: 145000,
      bankAccounts: INITIAL_BANK_ACCOUNTS,
      transactions: INITIAL_TRANSACTIONS,
    };
  }
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      const initial: WalletState = {
        balance: 24560,
        pendingPayouts: 0,
        totalWithdrawn: 145000,
        bankAccounts: INITIAL_BANK_ACCOUNTS,
        transactions: INITIAL_TRANSACTIONS,
      };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(initial));
      return initial;
    }
    return JSON.parse(saved);
  } catch {
    return {
      balance: 24560,
      pendingPayouts: 0,
      totalWithdrawn: 145000,
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
