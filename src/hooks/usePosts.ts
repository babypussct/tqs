import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, getDocsFromCache, getDocsFromServer, where } from 'firebase/firestore';
import { db } from '../firebase';
import { Post } from '../types';

const CACHE_KEY = 'tqs_posts_last_fetch';

export function usePosts(isAdmin = false) {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let q: any = collection(db, 'posts');
    if (!isAdmin) {
      q = query(q, where('status', '==', 'published'), orderBy('createdAt', 'desc'));
    } else {
      q = query(q, orderBy('createdAt', 'desc'));
    }

    if (isAdmin) {
      const unsubscribe = onSnapshot(q, (snapshot) => {
        const postData: Post[] = [];
        snapshot.forEach((doc) => {
          postData.push({ id: doc.id, ...doc.data() } as Post);
        });
        setPosts(postData);
        setLoading(false);
      });
      return () => unsubscribe();
    }

    let isMounted = true;
    const fetchPosts = async () => {
      try {
        const lastFetchStr = sessionStorage.getItem(CACHE_KEY);
        const now = Date.now();
        const shouldFetchServer = !lastFetchStr || (now - parseInt(lastFetchStr)) > 3600000;

        let snapshot;
        if (shouldFetchServer) {
          snapshot = await getDocsFromServer(q);
          sessionStorage.setItem(CACHE_KEY, now.toString());
        } else {
          try {
            snapshot = await getDocsFromCache(q);
            if (snapshot.empty) snapshot = await getDocsFromServer(q);
          } catch {
            snapshot = await getDocsFromServer(q);
          }
        }

        if (!isMounted) return;

        const postData: Post[] = [];
        snapshot.forEach((doc) => {
          postData.push({ id: doc.id, ...doc.data() } as Post);
        });
        setPosts(postData);
      } catch (error) {
        console.error('Error fetching posts:', error);
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    fetchPosts();
    return () => { isMounted = false; };
  }, [isAdmin]);

  return { posts, loading };
}
