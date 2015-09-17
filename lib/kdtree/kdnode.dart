part of texturesynthesis.kdtree;

class KDNode {

  // Static
  KDNode insert(HPoint key, num val, KDNode t, int lev, int K) {
    if (t == null) {
      t = new KDNode(key, val);
    }
    else if(key.equals(t.k)) {

      if(t.deleted) {
        t.deleted = false;
        t.v = val;
      }
      else {
        throw new KeyDuplicateException();
      }

    }
    else if(key.coord[lev] > t.k.coord[lev]) {
      t.right = insert(key, val, t.right, (lev + 1) % K, K);
    }
    else {
      t.left = insert(key, val, t.left, (lev + 1) % K, K);
    }

    return t;
  }

  KDNode search(HPoint key, KDNode t,int K) {
    for(int lev = 0; t != null; lev = (lev + 1 ) % K) {

      if(!t.deleted && key.equals(t.k)) {
        return t;
      }
      else if(key.coord[lev] > t.k.coord[lev]) {
        t = t.right;
      }
      else  {
        t =  t.left;
      }
    }

    return null;
  }

  static KDNode delete(HPoint key, KDNode t, int lev, int K, bool refDeleted) {
    if (t ==  null) return null;

    if(!t.deleted && key.equals(t.k)) {
      t.deleted = true;
      refDeleted = true;
    }
    else if(key.coord[lev] > t.k.coord[lev]) {
      t.right = delete(key, t.right, (lev + 1) % K, K, refDeleted);
    }
    else {
      t.left = delete(key, t.left, (lev + 1) % K, K, refDeleted);
    }

    if(!t.deleted || t.left != null || t.right != null) {
      return t;
    }
    else {
      return null;
    }
  }

  static void rsearch(HPoint lowk, HPoint uppk, KDNode t, int lev, int K, List<KDNode> v) {
    if(t == null) return;

    if(lowk.coord[lev] <= t.k.coord[lev]) {
      rsearch(lowk, uppk, t.left, (lev + 1) % K, K, v);
    }

    int j;
    for(j = 0; j < K && lowk.coord[j] <= t.k.coord[j] && uppk.coord[j] >= t.k.coord[j]; j++);

    if(j == K && !t.deleted) v.add(t);

    if(uppk.coord[lev] > t.k.coord[lev]) {
      rsearch(lowk, uppk, t.right, (lev + 1) % K, K, v);
    }
  }


  HPoint k;
  num v;
  KDNode left, right;
  bool deleted;


}