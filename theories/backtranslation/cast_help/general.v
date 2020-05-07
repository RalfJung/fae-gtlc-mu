From fae_gtlc_mu.stlc_mu Require Export typing lang lib.fix.
From fae_gtlc_mu.cast_calculus Require Export types consistency.structural.
From fae_gtlc_mu.backtranslation.cast_help Require Export universe embed extract between factorize.
From Coq Require Export List.

(** emulation of a cast between an arbitrary pair of consistent types *)
(* recursively defined on the alternative consistency relation *)

Fixpoint 𝓕 {A : list (types.type * types.type)} {τi τf : cast_calculus.types.type} (P : cons_struct A τi τf) : expr :=
  match P with
  | consStarTGround _ τG G => extract τG G
  | consTGroundStar _ τG G => embed τG G
  | consTauStar _ τ τG pτnG pτnStar pτSτG pτConsτG pτGConsStar =>
    factorization (𝓕 pτConsτG) (𝓕 pτGConsStar)
  | consStarTau _ τ τG pτnG pτnStar pτSτG pStarConsτG pτGConsτ =>
    factorization (𝓕 pStarConsτG) (𝓕 pτGConsτ)
  | consBaseBase _ => identity
  | consStarStar _ => identity
  | consTSumTSum _ τ1 τ1' τ2 τ2' pCons1 pCons2 =>
    between_TSum
      (𝓕 pCons1)
      (𝓕 pCons2)
  | consTProdTProd _ τ1 τ1' τ2 τ2' pCons1 pCons2 =>
    between_TProd
      (𝓕 pCons1)
      (𝓕 pCons2)
  | consTArrowTArrow _ τ1 τ2 τ3 τ4 pCons31 pCons24 =>
    between_TArrow
      (𝓕 pCons31)
      (𝓕 pCons24)
  | consTRecTRecExposeCall _ τl τr pμτlμτrnotA pUnfτlUnfτr =>
    between_TRec
      (𝓕 pUnfτlUnfτr)
  (* | consTRecTRecUseCall _ τl τr i pμτlμtrinA => Lam ((Var (S i)) (Var 0)) *)
  | consTRecTRecUseCall _ τl τr i pμτlμtrinA => Var i
  end.

(* From fae_gtlc_mu.stlc_mu Require Export typing lang lib.fix. *)

Definition back_pair (p : cast_calculus.types.type * cast_calculus.types.type) : stlc_mu.types.type :=
  TArrow <<p.1>> <<p.2>>.

Definition PTClosed (p : cast_calculus.types.type * cast_calculus.types.type) : Prop :=
  cast_calculus.types.TClosed p.1 ∧ cast_calculus.types.TClosed p.2.

Lemma back_pair_closed p : PTClosed p → TClosed (back_pair p).
Proof.
  destruct p as [τ1 τ2]. intro H. destruct H as [a b].
  apply TArrow_closed; by apply back_closed.
Qed.

Lemma Forall_fmap_impl {A B : Type} (f : A → B) (X : list A) (P : A → Prop) (Q : B → Prop)
      (Himpl : forall a : A, P a → Q (f a)) (HP : Forall P X) : Forall Q (f <$> X).
Proof. induction X. apply Forall_nil. inversion HP. apply Forall_cons. auto. by apply IHX. Qed.

Lemma 𝓕_typed (A : list (cast_calculus.types.type * cast_calculus.types.type)) (pA : Forall (fun p => cast_calculus.types.TClosed p.1 ∧ cast_calculus.types.TClosed p.2) A)
      (τi τf : cast_calculus.types.type) (pτi : cast_calculus.types.TClosed τi) (pτf : cast_calculus.types.TClosed τf) (pτiConsτf : cons_struct A τi τf) :
  (map back_pair A) ⊢ₛ (𝓕 pτiConsτf) : (TArrow <<τi>> <<τf>>).
Proof.
  induction pτiConsτf; simpl.
  - apply extract_typed.
  - apply embed_typed.
  - eapply factorization_typed.
    apply IHpτiConsτf1; auto. by apply Ground_closed; eapply get_shape_is_ground.
    apply IHpτiConsτf2; auto. by apply Ground_closed; eapply get_shape_is_ground.
  - eapply factorization_typed.
    apply IHpτiConsτf1; auto. by apply Ground_closed; eapply get_shape_is_ground.
    apply IHpτiConsτf2; auto. by apply Ground_closed; eapply get_shape_is_ground.
  - apply identity_typed. apply TUnit_TClosed.
  - apply identity_typed. apply Universe_closed.
  - apply between_TSum_typed.
    apply IHpτiConsτf1; auto; by eapply (cast_calculus.types.TSum_closed1).
    apply IHpτiConsτf2; auto; by eapply (cast_calculus.types.TSum_closed2).
  - apply between_TProd_typed.
    apply IHpτiConsτf1; auto; by eapply (cast_calculus.types.TProd_closed1).
    apply IHpτiConsτf2; auto; by eapply (cast_calculus.types.TProd_closed2).
  - apply between_TArrow_typed.
    apply IHpτiConsτf1; auto; by eapply (cast_calculus.types.TArrow_closed1).
    apply IHpτiConsτf2; auto; by eapply (cast_calculus.types.TArrow_closed2).
  - apply between_TRec_typed.
    rewrite map_cons in IHpτiConsτf.
    repeat rewrite back_unfold_comm in IHpτiConsτf.
    apply IHpτiConsτf; auto; by apply cast_calculus.types.TRec_closed_unfold.
  - apply Var_typed.
    cut (TClosed <<(cast_calculus.types.TArrow (cast_calculus.types.TRec τl) (cast_calculus.types.TRec τr))>>). by simpl.
    by apply back_closed, cast_calculus.types.TArrow_closed.
    rewrite list_lookup_fmap. by rewrite pμτlμtrinA.
Qed.

Definition 𝓕c {A} {τi τf} (pC : cons_struct A τi τf) fs : stlc_mu.lang.expr :=
  (𝓕 pC).[stlc_mu.typing.env_subst fs].

(** 𝓕 pC is a value after substitution *)

Definition 𝓕cV {A} {τi τf} (pC : cons_struct A τi τf) fs (H : length A = length fs) : stlc_mu.lang.val :=
  match to_val (𝓕c pC fs) with
  | Some x => x
  | None => UnitV
  end.

Lemma 𝓕c_rewrite {A} {τi τf} (pC : cons_struct A τi τf) fs (H : length A = length fs) : 𝓕c pC fs = # (𝓕cV pC fs H).
Proof.
  unfold 𝓕cV.
  destruct pC.
  - rewrite /𝓕c /𝓕. by rewrite extract_no_subs to_of_val.
  - rewrite /𝓕c /𝓕. by rewrite embed_no_subs to_of_val.
  - rewrite /𝓕c /𝓕. rewrite factorization_subst_rewrite. fold (𝓕 pC1). fold (𝓕 pC2).
    by rewrite to_of_val.
  - rewrite /𝓕c /𝓕. rewrite factorization_subst_rewrite. fold (𝓕 pC2). fold (𝓕 pC2).
    by rewrite to_of_val.
  - rewrite /𝓕c /𝓕. by asimpl.
  - rewrite /𝓕c /𝓕. by asimpl.
  - rewrite /𝓕c /𝓕. rewrite between_TSum_subst_rewrite.
    fold (𝓕 pC1).
    fold (𝓕 pC2).
    by rewrite to_of_val.
  - rewrite /𝓕c /𝓕. rewrite between_TProd_subst_rewrite.
    by rewrite to_of_val.
  - rewrite /𝓕c /𝓕. rewrite between_TArrow_subst_rewrite.
    by rewrite to_of_val.
  - rewrite /𝓕c /𝓕. rewrite between_TRec_subst_rewrite.
    by rewrite to_of_val.
  - rewrite /𝓕c /𝓕.
    assert (Hi : i < length fs). rewrite -H; apply lookup_lt_is_Some; by econstructor.
    destruct (fs !! i) eqn:Hf.
    simpl.
    erewrite env_subst_lookup. by rewrite to_of_val.
    apply Hf.
    exfalso.
    assert (length fs ≤ i). by apply lookup_ge_None_1.
    lia.
Qed.


From fae_gtlc_mu.stlc_mu Require Export lang.

Lemma expr_double_subst (e : expr) σ1 σ2 : e.[σ1].[σ2] = e.[σ1 >> σ2].
Proof. by asimpl. Qed.

Lemma 𝓕c_closed_gen {A} {τi τf} (pC : cons_struct A τi τf) fs (Hfsc : Forall VClosed fs) :
  forall n, (length A = n + length fs) → forall σ, (𝓕 pC).[upn n (env_subst fs)].[upn n σ] = (𝓕 pC).[upn n (env_subst fs)].
Proof.
  generalize dependent fs.
  induction pC; intros fs Hfsc; rewrite /𝓕c /𝓕; intros n H.
  - intro. by repeat rewrite extract_no_subs.
  - intro. by repeat rewrite embed_no_subs.
  - intro. fold (𝓕 pC1). fold (𝓕 pC2).
    rewrite expr_double_subst. do 2 rewrite factorization_subst_rewrite.
    do 2 rewrite -expr_double_subst.
    rewrite IHpC1; auto. rewrite IHpC2; auto.
  - intro. fold (𝓕 pC1). fold (𝓕 pC2).
    rewrite expr_double_subst. do 2 rewrite factorization_subst_rewrite.
    do 2 rewrite -expr_double_subst.
    rewrite IHpC1; auto. rewrite IHpC2; auto.
  - intro; by asimpl.
  - intro; by asimpl.
  - fold (𝓕 pC1). fold (𝓕 pC2). intro σ.
    rewrite expr_double_subst. do 2 rewrite between_TSum_subst_rewrite.
    do 2 rewrite -expr_double_subst.
    rewrite IHpC1; auto. rewrite IHpC2; auto.
  - fold (𝓕 pC1). fold (𝓕 pC2). intro σ.
    rewrite expr_double_subst. do 2 rewrite between_TProd_subst_rewrite.
    do 2 rewrite -expr_double_subst.
    rewrite IHpC1; auto. rewrite IHpC2; auto.
  - fold (𝓕 pC1). fold (𝓕 pC2). intro σ.
    rewrite expr_double_subst. do 2 rewrite between_TArrow_subst_rewrite.
    do 2 rewrite -expr_double_subst.
    rewrite IHpC1; auto. rewrite IHpC2; auto.
  - fold (𝓕 pC). intro σ.
    rewrite expr_double_subst. do 2 rewrite between_TRec_subst_rewrite.
    cut (# between_TRec (𝓕 pC).[upn (S n) (env_subst fs)].[upn (S n) σ] = # between_TRec (𝓕 pC).[upn (S n) (env_subst fs)]). by asimpl.
    rewrite IHpC; auto. simpl. lia.
  - intro σ. asimpl.
    destruct (iter_up_cases i n (env_subst fs)) as [[-> eq] | [j [-> ->]]].
    + asimpl. by rewrite upn_lt.
    + assert (Hnj : n + j < length A). apply lookup_lt_is_Some. by econstructor. rewrite H in Hnj.
      assert (Hj : j < length fs). lia.
      destruct (fs !! j) eqn:Hf.
      * rewrite (env_subst_lookup fs _ v).
        assert (vc : EClosed v). apply ve_closed. eapply (Forall_lookup_1). apply Hfsc. apply Hf.
        asimpl. by do 2 rewrite vc. auto.
      * assert (length fs ≤ j). by apply lookup_ge_None_1. exfalso; lia.
Qed.


Lemma 𝓕c_closed {A} {τi τf} (pC : cons_struct A τi τf) fs (H : length A = length fs) (Hfsc : Forall VClosed fs) :
  EClosed (𝓕c pC fs).
Proof.
  intro σ. rewrite /𝓕c. cut ((𝓕 pC).[upn 0 (env_subst fs)].[upn 0 σ] = (𝓕 pC).[upn 0 (env_subst fs)]). by asimpl.
  by apply 𝓕c_closed_gen.
Qed.
