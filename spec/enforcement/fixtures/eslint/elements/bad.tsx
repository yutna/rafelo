export function Form() {
  return (
    <form>
      <button type="submit">Save</button>
      <input name="email" />
      <select name="role">
        <option value="member">Member</option>
      </select>
      <textarea name="note" />
    </form>
  );
}
