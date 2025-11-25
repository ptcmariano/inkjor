'use client';

import { createSupabaseBrowser } from '@/lib/supabasefront';
import { redirect, useRouter } from 'next/navigation';
import { useCallback, useEffect, useMemo, useState } from 'react';


interface UserProfile {
    email: string;
    user_metadata: {
        picture?: string;
        [key: string]: any;
    };
}

export default function DashboardPage() {
    const [user, setUser] = useState<UserProfile>({ email: '', user_metadata: { picture: '' } });

    useEffect(() => {
        const supabase = createSupabaseBrowser();
        supabase.auth.getUser().then(({ data, error }) => {
            if (error) {
                console.error(error);
                return;
            }
            setUser({ email: data.user?.email || '', user_metadata: data.user?.user_metadata || { picture: '' } });
            if (!data.user?.email) redirect("/auth/login");
            redirect("/protected/dashboard");
        });
    }, []);

    return (
        <main className="p-6 space-y-8">
            <section className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div>
                    <h1 className="text-2xl font-semibold">Dashboard</h1>
                    <p className="text-sm text-gray-600">Bem-vindo Inkjor.</p>
                    <div className="mt-4 flex items-center gap-4">
                        <div>
                            <p className="text-sm text-gray-500">Logado como:</p>
                            <p className="font-medium">{user?.email}</p>
                        </div>
                        {user?.user_metadata?.picture && (
                            <img
                                src={user.user_metadata.picture}
                                alt="Avatar do usuário"
                                className="h-12 w-12 rounded-full object-cover"
                                referrerPolicy="no-referrer"
                            />
                        )}
                    </div>
                </div>
            </section>
        </main>

    );
}