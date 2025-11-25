'use client';
import { useEffect, useState } from 'react';
import { createSupabaseBrowser } from '@/lib/supabasefront';
import { useRouter } from 'next/navigation';

export default function HomeClient() {
  const [user, setUser] = useState({ email: '' });
  const router = useRouter();

  useEffect(() => {
    const supabase = createSupabaseBrowser();
    supabase.auth.getUser().then(({ data, error }) => {
      if (error || !data.user) {
        router.push("/auth");
        return;
      }
      setUser({ email: data.user.email || '' });
      router.push("/protected/dashboard");
    });
  }, [router]);

  return <div>Loading...</div>;
}