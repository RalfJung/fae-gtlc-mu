From Autosubst Require Export Autosubst.
From fae_gtlc_mu Require Import prelude.
Require Coq.Logic.JMeq.

Inductive type :=
  | TUnit : type
  | TProd (τ1 τ2 : type) : type
  | TSum (τ1 τ2 : type) : type
  | TArrow (τ1 τ2 : type) : type
  | TRec (τ : {bind 1 of type})
  | TVar (x : var)
  | TUnknown : type.

Instance type_eqdec : EqDecision type.
Proof.
  unfold EqDecision.
  intro τ.
  induction τ; intros τ'; destruct τ'; try (by (apply right; intro abs; inversion abs)).
  - by apply left.
  - destruct (IHτ1 τ'1) as [-> | neq].
    + destruct (IHτ2 τ'2) as [-> | neq].
      * by apply left.
      * apply right. intro abs. inversion abs. contradiction.
    + apply right. intro abs. inversion abs. contradiction.
  - destruct (IHτ1 τ'1) as [-> | neq].
    + destruct (IHτ2 τ'2) as [-> | neq].
      * by apply left.
      * apply right. intro abs. inversion abs. contradiction.
    + apply right. intro abs. inversion abs. contradiction.
  - destruct (IHτ1 τ'1) as [-> | neq].
    + destruct (IHτ2 τ'2) as [-> | neq].
      * by apply left.
      * apply right. intro abs. inversion abs. contradiction.
    + apply right. intro abs. inversion abs. contradiction.
  - destruct (IHτ τ0) as [-> | neq].
    + by apply left.
    + apply right. intro abs. inversion abs. contradiction.
  - destruct (decide (x = x0)) as [-> | neq].
    + by apply left.
    + apply right. intro abs. inversion abs. contradiction.
  - by apply left.
Qed.

Instance Is_Unknown_dec (τ : type) : Decision (τ = TUnknown) := type_eqdec τ TUnknown.

Instance Ids_type : Ids type. derive. Defined.
Instance Rename_type : Rename type. derive. Defined.
Instance Subst_type : Subst type. derive. Defined.
Instance SubstLemmas_typer : SubstLemmas type. derive. Qed.

Definition Is_Closed τ := forall τ', τ.[τ'/] = τ.

Definition TClosed τ := forall σ, τ.[σ] = τ.
(* boring properties about substitution {{{ *)

Lemma scomp_comp (σ1 σ2 : var → type) τ : (subst σ1 ∘ subst σ2) τ = subst (σ2 >> σ1) τ.
Proof. by asimpl. Qed.

Lemma scomp_assoc (σ1 σ2 σ3 : var → type) : (σ1 >> σ2) >> σ3 = σ1 >> (σ2 >> σ3).
Proof. by asimpl. Qed.

Lemma subst_commut (τ : type) (σ : var → type) : up σ >> scons (τ.[σ]) ids = scons τ ids >> σ.
Proof. by asimpl. Qed.

Lemma subst_fv_upn_yes n m σ : (TVar (n + m)).[upn n σ] = ((TVar m).[σ].[ren (+n)]).
Proof.
  asimpl.
  induction n.
  - by asimpl.
  - asimpl. rewrite IHn. by asimpl.
Qed.

Lemma subst_fv_upn_no n m σ : n < m → (TVar n).[upn m σ] = TVar n.
Proof.
  generalize dependent n.
  induction m.
  - intros. exfalso. lia.
  - intros. destruct n.
    + by asimpl.
    + asimpl. asimpl in IHm. rewrite IHm. by asimpl. lia.
Qed.

Lemma subst_fv_upn_cases k n σ : ((TVar k).[upn n σ] = TVar k ∧ k < n) +
                                 { j : nat | (k = (n + j)%nat) ∧ (TVar k).[upn n σ] = (TVar j).[σ].[ren (+n)]  }.
Proof.
  destruct (decide (k < n)).
  - apply inl. split. apply subst_fv_upn_no; auto. auto.
  - apply inr. exists (k - n). split. lia. rewrite -subst_fv_upn_yes.
    assert (triv : k = n + (k - n)). lia. by rewrite -triv.
Qed.

(* }}} *)

(* properties about closedness {{{ *)

Lemma TUnit_TClosed : TClosed TUnit.
Proof. try by (intro σ; by asimpl). Qed.

Lemma TArrow_closed {τ1 τ2} : TClosed τ1 → TClosed τ2 → TClosed (TArrow τ1 τ2).
Proof.
  unfold TClosed.
  intros H1 H2 τ'.
  simpl. by rewrite H1 H2.
Qed.

Lemma TArrow_closed1 {τ1 τ2} : TClosed (TArrow τ1 τ2) → TClosed τ1.
Proof.
  unfold TClosed.
  intros H σ.
  assert (H' : TArrow τ1.[σ] τ2.[σ] = TArrow τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TArrow_closed2 {τ1 τ2} : TClosed (TArrow τ1 τ2) → TClosed τ2.
Proof.
  unfold TClosed.
  intros H σ.
  assert (H' : TArrow τ1.[σ] τ2.[σ] = TArrow τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H2.
Qed.

Lemma TProd_closed {τ1 τ2} : TClosed τ1 → TClosed τ2 → TClosed (TProd τ1 τ2).
Proof.
  unfold TClosed.
  intros H1 H2 τ'.
  simpl. by rewrite H1 H2.
Qed.

Lemma TProd_closed1 {τ1 τ2} : TClosed (TProd τ1 τ2) → TClosed τ1.
Proof.
  unfold TClosed.
  intros H σ.
  assert (H' : TProd τ1.[σ] τ2.[σ] = TProd τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TProd_closed2 {τ1 τ2} : TClosed (TProd τ1 τ2) → TClosed τ2.
Proof.
  unfold TClosed.
  intros H σ.
  assert (H' : TProd τ1.[σ] τ2.[σ] = TProd τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H2.
Qed.

Lemma TSum_closed {τ1 τ2} : TClosed τ1 → TClosed τ2 → TClosed (TSum τ1 τ2).
Proof.
  unfold TClosed.
  intros H1 H2 τ'.
  simpl. by rewrite H1 H2.
Qed.

Lemma TSum_closed1 {τ1 τ2} : TClosed (TSum τ1 τ2) → TClosed τ1.
Proof.
  unfold TClosed.
  intros H σ.
  assert (H' : TSum τ1.[σ] τ2.[σ] = TSum τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TSum_closed2 {τ1 τ2} : TClosed (TSum τ1 τ2) → TClosed τ2.
Proof.
  unfold TClosed.
  intros H σ.
  assert (H' : TSum τ1.[σ] τ2.[σ] = TSum τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H2.
Qed.

Lemma TRec_closed {τ} : TClosed τ → TClosed (TRec τ).
Proof. intros H σ. asimpl. by rewrite H. Qed.

Lemma TRec_TArrow_closed {τ1 τ2} : TClosed (TRec τ1) → TClosed (TRec τ2) → TClosed (TRec (TArrow τ1 τ2)).
Proof.
  intros H1 H2.
  intro. simpl.
  assert (H1' : (TRec τ1).[σ] = TRec τ1). by rewrite H1. asimpl in H1'. inversion H1' as [H1'']. do 2 rewrite H1''.
  assert (H2' : (TRec τ2).[σ] = TRec τ2). by rewrite H2. asimpl in H2'. inversion H2' as [H2'']. do 2 rewrite H2''.
  done.
Qed.

Lemma no_var_is_closed x : not (TClosed (TVar x)).
Proof.
  intro H. assert (abs : (TVar x).[ren (+1)] = TVar x); first by apply H.
  inversion abs; lia.
Qed.

Definition TnClosed : nat → type → Prop := fun n τ => forall σ, τ.[upn n σ] = τ.

Lemma TArrow_nclosed1 {τ1 τ2} {n} : TnClosed n (TArrow τ1 τ2) → TnClosed n τ1.
Proof.
  unfold TnClosed.
  intros H σ.
  assert (H' : TArrow τ1.[upn n σ] τ2.[upn n σ] = TArrow τ1 τ2). asimpl in H. by rewrite H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TArrow_nclosed2 {τ1 τ2} {n} : TnClosed n (TArrow τ1 τ2) → TnClosed n τ2.
Proof.
  unfold TnClosed.
  intros H σ.
  assert (H' : TArrow τ1.[upn n σ] τ2.[upn n σ] = TArrow τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H2.
Qed.

Lemma TArrow_nclosed {τ1 τ2} {n} : (TnClosed n τ1 ∧ TnClosed n τ2) ↔ TnClosed n (TArrow τ1 τ2).
Proof.
  split. intros (H1, H2). intro σ. asimpl. by rewrite H1 H2.
  intros. split. by eapply TArrow_nclosed1. by eapply TArrow_nclosed2.
Qed.

Lemma TProd_nclosed1 {τ1 τ2} {n} : TnClosed n (TProd τ1 τ2) → TnClosed n τ1.
Proof.
  unfold TnClosed.
  intros H σ.
  assert (H' : TProd τ1.[upn n σ] τ2.[upn n σ] = TProd τ1 τ2). asimpl in H. by rewrite H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TProd_nclosed2 {τ1 τ2} {n} : TnClosed n (TProd τ1 τ2) → TnClosed n τ2.
Proof.
  unfold TnClosed.
  intros H σ.
  assert (H' : TProd τ1.[upn n σ] τ2.[upn n σ] = TProd τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H2.
Qed.

Lemma TSum_nclosed1 {τ1 τ2} {n} : TnClosed n (TSum τ1 τ2) → TnClosed n τ1.
Proof.
  unfold TnClosed.
  intros H σ.
  assert (H' : TSum τ1.[upn n σ] τ2.[upn n σ] = TSum τ1 τ2). asimpl in H. by rewrite H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TSum_nclosed2 {τ1 τ2} {n} : TnClosed n (TSum τ1 τ2) → TnClosed n τ2.
Proof.
  unfold TnClosed.
  intros H σ.
  assert (H' : TSum τ1.[upn n σ] τ2.[upn n σ] = TSum τ1 τ2). asimpl in H; by rewrite H.
  inversion H'.
  by do 2 rewrite H2.
Qed.

Lemma TRec_nclosed1 {τ} {n} : TnClosed n (TRec τ) → TnClosed (S n) τ.
Proof.
  intros H σ.
  assert (H' : TRec τ.[upn (S n) σ] = TRec τ). specialize (H σ). by asimpl in H.
  inversion H'.
  by do 2 rewrite H1.
Qed.

Lemma TRec_nclosed {τ} {n} : TnClosed n (TRec τ) ↔ TnClosed (S n) τ.
Proof.
  split. apply TRec_nclosed1.
  intros H σ.
  asimpl. apply f_equal. apply H.
Qed.

Lemma TnClosed_var (x n : nat) : TnClosed n (TVar x) ↔ x < n.
Proof.
  split.
  - intros.
    destruct (subst_fv_upn_cases x n (ren (+1))) as [[_ eq] | [j [-> _]]].
    + auto.
    + exfalso. unfold TnClosed in H.
      specialize (H (ren (+1))).
      rewrite subst_fv_upn_yes in H.
      asimpl in H. inversion H. lia.
  - intros. intro σ. by apply subst_fv_upn_no.
Qed.

Lemma le_exists_add x y : x ≤ y → exists z, x + z = y.
Proof. intros. exists (y - x). lia. Qed.

Lemma TnClosed_mon τ (n m : nat) : n ≤ m → TnClosed n τ → TnClosed m τ.
Proof.
  intros ple pnτ. intro σ. destruct (le_exists_add n m ple) as [z <-]. generalize σ. clear σ.
  simpl. induction z. asimpl. intro σ. by rewrite pnτ. intro σ. cut (τ.[upn (n + S z) σ] = τ.[upn (n + z) (up σ)]).
  intro. rewrite H. apply IHz. lia. by asimpl.
Qed.

Lemma TnClosed_ren_gen (τ : type) :
  forall (n m : nat) (pτ : TnClosed n τ) (l : nat), TnClosed (m + n) τ.[upn l (ren (+m))].
Proof.
  induction τ; intros.
  - by asimpl.
  - specialize (IHτ1 n m ltac:(by eapply TProd_nclosed1) l).
    specialize (IHτ2 n m ltac:(by eapply TProd_nclosed2) l).
    simpl. intro σ. simpl. by rewrite IHτ1 IHτ2.
  - specialize (IHτ1 n m ltac:(by eapply TSum_nclosed1) l).
    specialize (IHτ2 n m ltac:(by eapply TSum_nclosed2) l).
    simpl. intro σ. simpl. by rewrite IHτ1 IHτ2.
  - specialize (IHτ1 n m ltac:(by eapply TArrow_nclosed1) l).
    specialize (IHτ2 n m ltac:(by eapply TArrow_nclosed2) l).
    simpl. intro σ. simpl. by rewrite IHτ1 IHτ2.
  - simpl. apply TRec_nclosed.
    specialize (IHτ (S n) m ltac:(by apply TRec_nclosed) (S l)).
    by asimpl in *.
  - destruct (subst_fv_upn_cases x l (ren (+m))) as [[-> p] | [j [eq ->]]].
    + eapply (TnClosed_mon _ n). lia. apply pτ.
    + asimpl. apply TnClosed_var.
      assert (H : x < n). by apply TnClosed_var. lia.
  - by asimpl.
Qed.

Lemma TnClosed_ren (τ : type) :
  forall (n m : nat) (pτ : TnClosed n τ), TnClosed (m + n) τ.[ren (+m)].
Proof. intros. cut (TnClosed (m + n) τ.[upn 0 (ren (+m))]). by asimpl. by apply TnClosed_ren_gen. Qed.

Lemma TnClosed_subst_gen n τ τ' : forall m, TnClosed (S (m + n)) τ' → TnClosed n τ → TnClosed ((m + n)) τ'.[upn m (τ .: ids)].
Proof.
  generalize dependent n.
  induction τ'; intros.
  - asimpl. intro σ; by asimpl.
  - asimpl.
    specialize (IHτ'1 n m ltac:(by eapply TProd_nclosed1) H0).
    specialize (IHτ'2 n m ltac:(by eapply TProd_nclosed2) H0).
    intro σ. simpl. by rewrite IHτ'1 IHτ'2.
  - asimpl.
    specialize (IHτ'1 n m ltac:(by eapply TSum_nclosed1) H0).
    specialize (IHτ'2 n m ltac:(by eapply TSum_nclosed2) H0).
    intro σ. simpl. by rewrite IHτ'1 IHτ'2.
  - asimpl.
    specialize (IHτ'1 n m ltac:(by eapply TArrow_nclosed1) H0).
    specialize (IHτ'2 n m ltac:(by eapply TArrow_nclosed2) H0).
    intro σ. simpl. by rewrite IHτ'1 IHτ'2.
  - simpl.
    apply TRec_nclosed.
    apply (IHτ' n (S m)). by apply TRec_nclosed. auto.
  - destruct (subst_fv_upn_cases x m (τ .: ids)) as [[-> p] | [j [eq ->]]].
    + apply TnClosed_var. lia.
    + destruct j.
      * asimpl. by apply TnClosed_ren.
      * asimpl. assert (p1 : x < S (m + n)). by apply TnClosed_var.
        apply TnClosed_var. lia.
  - by asimpl.
Qed.

Lemma TnClosed_subst n τ τ' : TnClosed (S n) τ' → TnClosed n τ → TnClosed n τ'.[τ/].
Proof. intros. rewrite -(upn0 (τ .: ids)). apply (TnClosed_subst_gen n τ τ' 0); auto. Qed.

Lemma TRec_closed_unfold {τ} : TClosed (TRec τ) → TClosed (τ.[TRec τ/]).
Proof. intro. cut (TnClosed 0 τ.[TRec τ/]). by simpl. apply TnClosed_subst.
       apply TRec_nclosed. by simpl. by simpl.
Qed.

Ltac closed_solver :=
  ( by eapply TUnit_TClosed
  || by eapply TArrow_closed
  || by eapply TArrow_closed1
  || by eapply TArrow_closed2
  || by eapply TProd_closed
  || by eapply TProd_closed1
  || by eapply TProd_closed2
  || by eapply TSum_closed
  || by eapply TSum_closed1
  || by eapply TSum_closed2
  ).

(* }}} *)

(* ground types, inert casts... {{{ *)

Inductive Ground : type → Type :=
  | Ground_TUnit : Ground TUnit
  | Ground_TProd : Ground (TProd TUnknown TUnknown)
  | Ground_TSum : Ground (TSum TUnknown TUnknown)
  | Ground_TArrow : Ground (TArrow TUnknown TUnknown)
  | Ground_TRec : Ground (TRec TUnknown).

Definition Ground_dec (τ : type) : TDecision (Ground τ).
  destruct τ.
  - apply inl; constructor.
  - destruct (Is_Unknown_dec τ1). rewrite e.
    destruct (Is_Unknown_dec τ2). rewrite e0.
    + apply inl. constructor.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
  - destruct (Is_Unknown_dec τ1). rewrite e.
    destruct (Is_Unknown_dec τ2). rewrite e0.
    + apply inl. constructor.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
  - destruct (Is_Unknown_dec τ1). rewrite e.
    destruct (Is_Unknown_dec τ2). rewrite e0.
    + apply inl. constructor.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
  - destruct (Is_Unknown_dec τ). rewrite e.
    + apply inl. constructor.
    + apply inr. intro aaa. inversion aaa. apply n. by symmetry.
  - apply inr. intro aaa. inversion aaa.
  - apply inr. intro aaa. inversion aaa.
Defined.

(* Checking if two GROUND TYPES are equal *)
Definition Ground_equal {τ1 τ2 : type} (G1 : Ground τ1) (G2 : Ground τ2) : Prop := τ1 = τ2.

(* Distinction between inert and active as in formalisation of Jeremy *)
Inductive ICP : type → type → Prop :=
  | TArrow_TArrow_icp τ1 τ2 τ1' τ2' : ICP (TArrow τ1 τ2) (TArrow τ1' τ2')
  | TGround_TUnknown_icp {τ} (G : Ground τ) : ICP τ TUnknown.

Lemma Unique_Ground_Proof τ (G1 : Ground τ) (G2 : Ground τ) : G1 = G2.
Proof.
  destruct G1; generalize_eqs G2; intros; destruct G2; try inversion H; try by rewrite H0.
Qed.

Lemma Unique_ICP_proof τi τf (Ip1 : ICP τi τf) (Ip2 : ICP τi τf) : Ip1 = Ip2.
Proof.
  destruct Ip1.
  - generalize_eqs Ip2.
    intros.
    destruct Ip2.
    simplify_eq.
      by rewrite H1.
      inversion H0.
  - generalize_eqs Ip2.
    intros.
    destruct Ip2.
    simplify_eq.
    rewrite (Unique_Ground_Proof τ G G0).
      by rewrite -H0.
Qed.






(* possibly with sigma type and proof of groundness *)
Definition get_shape (τ : type) : option type :=
  match τ with
  | TUnit => None
  | TProd x x0 => Some (TProd TUnknown TUnknown)
  | TSum x x0 => Some (TSum TUnknown TUnknown)
  | TArrow x x0 => Some (TArrow TUnknown TUnknown)
  | TRec τ => Some (TRec TUnknown)
  | TVar x => None
  | TUnknown => None
  end.

Lemma get_shape_is_ground {τ τG : type} : get_shape τ = Some τG -> Ground τG.
Proof.
  intro.
  destruct τ; simplify_eq; destruct τG; inversion H; constructor.
Qed.

(* }}} *)

Lemma Ground_closed {τG} (G : Ground τG) : TClosed τG.
Proof. destruct G; intro σ; by asimpl. Qed.

(* notations {{{ *)

Notation "⋆" := TUnknown : type_scope.
Infix "×" := TProd (at level 150) : type_scope.
Infix "+" := TSum : type_scope.

(* }}} *)



Lemma TClosed_easy : forall τ n, τ.[upn n (TUnit .: ids)] = τ → TnClosed n τ.
Proof.
  intro τ.
  induction τ; intros n eq.
  - intro σ; by asimpl.
  - asimpl in eq. inversion eq.
    specialize (IHτ1 n H0). specialize (IHτ2 n H1).
    rewrite IHτ1 IHτ2. intro σ. asimpl. by rewrite IHτ1 IHτ2.
  - asimpl in eq. inversion eq.
    specialize (IHτ1 n H0). specialize (IHτ2 n H1).
    rewrite IHτ1 IHτ2. intro σ. asimpl. by rewrite IHτ1 IHτ2.
  - asimpl in eq. inversion eq.
    specialize (IHτ1 n H0). specialize (IHτ2 n H1).
    rewrite IHτ1 IHτ2. intro σ. asimpl. by rewrite IHτ1 IHτ2.
  - apply TRec_nclosed. apply IHτ. asimpl in eq. inversion eq. by do 2 rewrite H0.
  - asimpl in eq. destruct (iter_up_cases x n (TUnit .: ids)) as [[a p]| [j [b eq']]].
    by apply TnClosed_var. exfalso. rewrite eq in eq'. destruct j; asimpl in eq'. inversion eq'.
    inversion eq'. lia.
  - intro σ; by asimpl.
Qed.

Instance TClosed_dec τ : Decision (TClosed τ).
Proof.
  destruct (decide (τ.[TUnit/] = τ)).
  apply left. cut (TnClosed 0 τ). by simpl. apply TClosed_easy. by asimpl.
  apply right. intro abs. assert (H : τ.[TUnit/] = τ). by rewrite abs. contradiction.
Qed.
