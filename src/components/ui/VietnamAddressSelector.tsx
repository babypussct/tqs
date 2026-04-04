import React, { useState, useEffect } from 'react';
import { ChevronDown, Loader2 } from 'lucide-react';

interface Location {
  name: string;
  code: number;
}

interface AddressSelectorProps {
  value: string; // The joined address string
  onChange: (value: string) => void;
  error?: boolean;
}

export default function VietnamAddressSelector({ value, onChange, error }: AddressSelectorProps) {
  const [provinces, setProvinces] = useState<Location[]>([]);
  const [districts, setDistricts] = useState<Location[]>([]);
  const [wards, setWards] = useState<Location[]>([]);

  const [selectedProvince, setSelectedProvince] = useState<Location | null>(null);
  const [selectedDistrict, setSelectedDistrict] = useState<Location | null>(null);
  const [selectedWard, setSelectedWard] = useState<Location | null>(null);
  const [streetAddress, setStreetAddress] = useState('');

  const [loadingProvinces, setLoadingProvinces] = useState(false);
  const [loadingDistricts, setLoadingDistricts] = useState(false);
  const [loadingWards, setLoadingWards] = useState(false);

  // Fetch Provinces
  useEffect(() => {
    const fetchProvinces = async () => {
      setLoadingProvinces(true);
      try {
        const res = await fetch('https://provinces.open-api.vn/api/p/');
        const data = await res.json();
        setProvinces(data);
      } catch (err) {
        console.error('Lỗi khi tải danh sách tỉnh/thành', err);
      } finally {
        setLoadingProvinces(false);
      }
    };
    fetchProvinces();
  }, []);

  // Fetch Districts when Province changes
  useEffect(() => {
    if (!selectedProvince) {
      setDistricts([]);
      setWards([]);
      return;
    }
    const fetchDistricts = async () => {
      setLoadingDistricts(true);
      try {
        const res = await fetch(`https://provinces.open-api.vn/api/p/${selectedProvince.code}?depth=2`);
        const data = await res.json();
        setDistricts(data.districts || []);
      } catch (err) {
        console.error('Lỗi khi tải danh sách quận/huyện', err);
      } finally {
        setLoadingDistricts(false);
      }
    };
    fetchDistricts();
  }, [selectedProvince]);

  // Fetch Wards when District changes
  useEffect(() => {
    if (!selectedDistrict) {
      setWards([]);
      return;
    }
    const fetchWards = async () => {
      setLoadingWards(true);
      try {
        const res = await fetch(`https://provinces.open-api.vn/api/d/${selectedDistrict.code}?depth=2`);
        const data = await res.json();
        setWards(data.wards || []);
      } catch (err) {
        console.error('Lỗi khi tải danh sách phường/xã', err);
      } finally {
        setLoadingWards(false);
      }
    };
    fetchWards();
  }, [selectedDistrict]);

  // Update onChange whenever components change
  useEffect(() => {
    const parts = [];
    if (streetAddress) parts.push(streetAddress);
    if (selectedWard) parts.push(selectedWard.name);
    if (selectedDistrict) parts.push(selectedDistrict.name);
    if (selectedProvince) parts.push(selectedProvince.name);

    const newAddress = parts.join(', ');
    onChange(newAddress);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [streetAddress, selectedWard, selectedDistrict, selectedProvince]);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Province */}
        <div className="relative">
          <label className="block text-xs text-gray-500 dark:text-zinc-400 mb-1">Tỉnh / Thành phố *</label>
          <div className="relative">
            <select
              value={selectedProvince?.code || ''}
              onChange={(e) => {
                const p = provinces.find((x) => x.code === Number(e.target.value));
                setSelectedProvince(p || null);
                setSelectedDistrict(null);
                setSelectedWard(null);
              }}
              className={`w-full appearance-none bg-gray-50 dark:bg-zinc-950 border ${
                error && !selectedProvince ? 'border-red-500' : 'border-gray-300 dark:border-zinc-700'
              } rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all truncate pr-10`}
            >
              <option value="" disabled>-- Chọn Tỉnh / Thành phố --</option>
              {provinces.map((p) => (
                <option key={p.code} value={p.code}>
                  {p.name}
                </option>
              ))}
            </select>
            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
              {loadingProvinces ? <Loader2 className="w-4 h-4 animate-spin" /> : <ChevronDown className="w-4 h-4" />}
            </div>
          </div>
        </div>

        {/* District */}
        <div className="relative">
          <label className="block text-xs text-gray-500 dark:text-zinc-400 mb-1">Quận / Huyện *</label>
          <div className="relative">
            <select
              disabled={!selectedProvince}
              value={selectedDistrict?.code || ''}
              onChange={(e) => {
                const d = districts.find((x) => x.code === Number(e.target.value));
                setSelectedDistrict(d || null);
                setSelectedWard(null);
              }}
              className={`w-full appearance-none bg-gray-50 dark:bg-zinc-950 border ${
                error && selectedProvince && !selectedDistrict ? 'border-red-500' : 'border-gray-300 dark:border-zinc-700'
              } rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all truncate pr-10 disabled:opacity-50 disabled:cursor-not-allowed`}
            >
              <option value="" disabled>-- Chọn Quận / Huyện --</option>
              {districts.map((d) => (
                <option key={d.code} value={d.code}>
                  {d.name}
                </option>
              ))}
            </select>
            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
              {loadingDistricts ? <Loader2 className="w-4 h-4 animate-spin" /> : <ChevronDown className="w-4 h-4" />}
            </div>
          </div>
        </div>

        {/* Ward */}
        <div className="relative">
          <label className="block text-xs text-gray-500 dark:text-zinc-400 mb-1">Phường / Xã *</label>
          <div className="relative">
            <select
              disabled={!selectedDistrict}
              value={selectedWard?.code || ''}
              onChange={(e) => {
                const w = wards.find((x) => x.code === Number(e.target.value));
                setSelectedWard(w || null);
              }}
              className={`w-full appearance-none bg-gray-50 dark:bg-zinc-950 border ${
                error && selectedDistrict && !selectedWard ? 'border-red-500' : 'border-gray-300 dark:border-zinc-700'
              } rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all truncate pr-10 disabled:opacity-50 disabled:cursor-not-allowed`}
            >
              <option value="" disabled>-- Chọn Phường / Xã --</option>
              {wards.map((w) => (
                <option key={w.code} value={w.code}>
                  {w.name}
                </option>
              ))}
            </select>
            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
              {loadingWards ? <Loader2 className="w-4 h-4 animate-spin" /> : <ChevronDown className="w-4 h-4" />}
            </div>
          </div>
        </div>
      </div>

      {/* Street Address */}
      <div className="relative">
        <label className="block text-xs text-gray-500 dark:text-zinc-400 mb-1">Địa chỉ cụ thể (Số nhà, Tên đường) *</label>
        <input
          type="text"
          value={streetAddress}
          onChange={(e) => setStreetAddress(e.target.value)}
          placeholder="Số nhà, ngõ/ngách, tên đường..."
          className={`w-full bg-gray-50 dark:bg-zinc-950 border ${
            error && !streetAddress ? 'border-red-500' : 'border-gray-300 dark:border-zinc-700'
          } rounded-xl px-4 py-3 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all`}
        />
      </div>
    </div>
  );
}
