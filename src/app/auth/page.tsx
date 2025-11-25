'use client';

import { createSupabaseBrowser } from '@/lib/supabasefront';

export default function LoginPage() {
    const supabase = createSupabaseBrowser();

    const loginWithGoogle = async () => {
        await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: { redirectTo: `${window.location.origin}/` }
        });
    };

    return (
        <main className="min-h-screen flex items-center justify-center p-6">
        <div className="max-w-sm w-full space-y-6">
            <h1 className="text-2xl font-semibold text-center">Entrar</h1>
            <button
            onClick={loginWithGoogle}
            className="w-full rounded-md bg-black text-white py-2 hover:bg-gray-800"
            >
            Entrar com Google
            </button>
        </div>
        </main>
    );
}